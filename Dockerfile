# ==============================================================================
# GIAI ĐOẠN 1 (STAGE 1): BUILDER
# Nhiệm vụ: Tải dependencies, dọn dẹp cache và chuẩn bị production artifacts
# ==============================================================================
FROM node:18-alpine AS builder

WORKDIR /app

# Tận dụng triệt để Docker Layer Caching bằng cách copy package.json trước
COPY package*.json ./

# Cài đặt chỉ các dependencies cần thiết cho production và xóa cache npm
RUN npm install --omit=dev && npm cache clean --force

# Sao chép mã nguồn ứng dụng
COPY . .

# ==============================================================================
# GIAI ĐOẠN 2 (STAGE 2): RUNTIME
# Nhiệm vụ: Sử dụng base image tinh gọn, chỉ trích xuất artifact từ builder
# Không chứa trình quản lý gói, cache hay công cụ build dư thừa
# ==============================================================================
FROM node:18-alpine

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Chỉ copy những tệp tin thực sự cần thiết từ stage builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/server.js ./

# Khai báo cổng ứng dụng
EXPOSE 3000

# Chạy dưới tài khoản người dùng phi đặc quyền node để tăng cường an ninh
USER node

# Khởi chạy ứng dụng với exec form
CMD ["node", "server.js"]
