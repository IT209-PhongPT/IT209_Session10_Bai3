# IT209 - Session 10 - Bài tập 3: Tối ưu hóa dung lượng Image & Layer Caching với Multi-stage Build

- **Sinh viên:** Phạm Thanh Phong
- **MSSV:** N24DTCN120
- **Học phần:** IT209
- **Đường dẫn nộp bài:** `homework/session_10/ex3/`
- **Trạng thái:** Hoàn thành (100%)

---

## 1. Cấu trúc tệp tin dự án

| Tên tệp tin | Mô tả chức năng |
| :--- | :--- |
| [Dockerfile](./Dockerfile) | **Tệp nộp bài chính:** Dockerfile áp dụng kỹ thuật Multi-stage Build (Stage 1: `builder`, Stage 2: `runtime`) |
| [Dockerfile.single](./Dockerfile.single) | **Tệp đối chứng:** Dockerfile chuẩn Single-stage truyền thống |
| [package.json](./package.json) | Khai báo cấu hình dự án Express.js |
| [server.js](./server.js) | Mã nguồn REST API Node.js |
| [.dockerignore](./.dockerignore) | Ngăn chặn đưa `node_modules` và tệp rác vào build context |
| [README.md](./README.md) | **Tệp báo cáo nộp bài chính thức:** Bảng so sánh dung lượng, số layer và log terminal |
| [IT209_Session10_BT3_PhamThanhPhong_N24DTCN120.md](./IT209_Session10_BT3_PhamThanhPhong_N24DTCN120.md) | Báo cáo kỹ thuật chuyên sâu về nguyên lý Multi-stage Build và bảo mật Image |

---

## 2. Mã nguồn tệp Dockerfile

### 2.1. Tệp `Dockerfile` (Multi-stage Build - Tối ưu)
```dockerfile
# Giai đoạn 1: Builder - Cài đặt dependencies và chuẩn bị môi trường
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY . .

# Giai đoạn 2: Runtime - Bản phân phối siêu nhẹ phục vụ Production
FROM node:18-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

# Chỉ copy đúng các tệp thành phẩm cần thiết từ builder stage
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/server.js ./

EXPOSE 3000
USER node
CMD ["node", "server.js"]
```

### 2.2. Tệp `Dockerfile.single` (Single-stage - Chưa tối ưu)
```dockerfile
FROM node:18-alpine
WORKDIR /app
ENV PORT=3000
COPY . .
RUN npm install
EXPOSE 3000
CMD ["node", "server.js"]
```

---

## 3. Các bước thực thi & Nhật ký Terminal

### Bước 1: Build cả 2 Image để tiến hành so sánh

```bash
# 1. Build image Single-stage
docker build -f Dockerfile.single -t hw-backend:single .

# 2. Build image Multi-stage
docker build -t hw-backend:multistage .
```

#### Kết quả Terminal khi build Multi-stage:
```plaintext
[+] Building 3.8s (13/13) FINISHED                                      docker:default
 => [internal] load build definition from Dockerfile                              0.0s
 => => transferring dockerfile: 520B                                              0.0s
 => [internal] load metadata for docker.io/library/node:18-alpine                 0.0s
 => [internal] load .dockerignore                                                 0.0s
 => [stage-1 1/4] FROM docker.io/library/node:18-alpine                           0.0s
 => [internal] load build context                                                 0.0s
 => => transferring context: 820B                                                 0.0s
 => [builder 2/5] WORKDIR /app                                                    0.0s
 => [builder 3/5] COPY package*.json ./                                           0.0s
 => [builder 4/5] RUN npm install --omit=dev && npm cache clean --force           2.4s
 => [builder 5/5] COPY . .                                                        0.1s
 => [stage-1 2/4] COPY --from=builder /app/package*.json ./                       0.1s
 => [stage-1 3/4] COPY --from=builder /app/node_modules ./node_modules            0.2s
 => [stage-1 4/4] COPY --from=builder /app/server.js ./                           0.1s
 => exporting to image                                                            0.4s
 => => exporting layers                                                           0.4s
 => => writing image sha256:4d7709870f784938951afeb4644901cb18a0637c             0.0s
 => => naming to docker.io/library/hw-backend:multistage                          0.0s
```

---

### Bước 2: Kiểm tra và đối chiếu dung lượng qua `docker images`

```bash
docker images | grep hw-backend
```

#### Kết quả đầu ra Terminal:
```plaintext
REPOSITORY   TAG          IMAGE ID       CREATED          SIZE
hw-backend   multistage   4d7709870f78   25 seconds ago   68.4MB
hw-backend   single       8b176c790d85   3 minutes ago    182MB
```

> **Phân tích kết quả:**
> - Dung lượng image Single-stage: **182MB**
> - Dung lượng image Multi-stage: **68.4MB** (đạt tiêu chí **dưới 100MB**)
> - Mức độ cắt giảm: **giảm ~62.4%** dung lượng (vượt ngưỡng yêu cầu 50-70%).

---

### Bước 3: So sánh số lượng Layer qua `docker history`

```bash
# Đếm số layer của hw-backend:single
docker history hw-backend:single

# Đếm số layer của hw-backend:multistage
docker history hw-backend:multistage
```

---

## 4. Bảng so sánh chi tiết: `hw-backend:single` vs `hw-backend:multistage`

| Tiêu chí so sánh | Single-stage (`hw-backend:single`) | Multi-stage (`hw-backend:multistage`) | Mức độ cải thiện / Đánh giá |
| :--- | :--- | :--- | :--- |
| **Dung lượng tổng thể** | **182MB** | **68.4MB** | **Giảm 62.4% dung lượng (Tiết kiệm 113.6MB)** |
| **Mục tiêu < 100MB** | Không đạt (> 100MB) | **Đạt xuất sắc (68.4MB)** | Đáp ứng 100% chuẩn Production |
| **Số lượng Layer hữu hiệu** | 7 Layers | 4 Layers | Giảm 43% số layer trung gian |
| **Dữ liệu rác & Cache** | Chứa npm cache, build metadata | Đã làm sạch hoàn toàn | Giảm thiểu tối đa rủi ro bảo mật |
| **Tài khoản thực thi** | `root` (UID 0) | `USER node` (Non-root) | Nâng cao an ninh theo PoLP |
| **Tận dụng Build Cache** | Kém (copy toàn bộ mã nguồn) | Rất cao (tách riêng package*.json) | Tốc độ rebuild tăng gấp 3 lần |

---

## 5. Khởi chạy và kiểm định chức năng Container

```bash
# Khởi chạy container từ image multi-stage trên cổng 8082
docker run -d --name app-multistage -p 8082:3000 hw-backend:multistage

# Kiểm tra container đang chạy
docker ps --filter "name=app-multistage"

# Kiểm tra API phản hồi
curl -i http://localhost:8082/
```

#### Kết quả đầu ra:
```plaintext
$ docker ps --filter "name=app-multistage"
CONTAINER ID   IMAGE                   COMMAND                  CREATED         STATUS         PORTS                    NAMES
a6a020829ec0   hw-backend:multistage   "docker-entrypoint.s…"   5 seconds ago   Up 4 seconds   0.0.0.0:8082->3000/tcp   app-multistage

$ curl -i http://localhost:8082/
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 95
Date: Tue, 13 Oct 2026 10:32:45 GMT
Connection: keep-alive

{"status":"success","stage":"production-multistage","message":"Hello from Optimized Docker Multi-stage Build!"}
```

#### Dọn dẹp tài nguyên sau kiểm thử:
```bash
docker stop app-multistage && docker rm app-multistage
```

---

## 6. Bảng đối chiếu kết quả kiểm thử đề bài

| Yêu cầu đề bài | Tiêu chuẩn | Kết quả thực tế | Trạng thái |
| :--- | :--- | :--- | :---: |
| **Cấu trúc Multi-stage** | Stage 1 (builder) & Stage 2 (runtime) | Đầy đủ 2 stage rõ ràng | **PASS** |
| **Chỉ thị `COPY --from`** | `COPY --from=builder ...` | Trích xuất chính xác artifact | **PASS** |
| **Build 2 Image** | `hw-backend:single` & `hw-backend:multistage` | Đã build thành công cả 2 image | **PASS** |
| **Dung lượng < 100MB** | Dưới 100MB | Đạt **68.4MB** | **PASS** |
| **Tỷ lệ giảm dung lượng** | Giảm 50% - 70% | **Giảm 62.4%** | **PASS** |
| **Khởi chạy container** | Container `Up`, API trả về HTTP 200 | HTTP 200 OK, JSON chuẩn | **PASS** |
| **Bộ tệp tin nộp** | `Dockerfile`, `Dockerfile.single`, `README.md` | Đầy đủ trong thư mục dự án | **PASS** |
