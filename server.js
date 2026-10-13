const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.json({
        status: 'success',
        stage: 'production-multistage',
        message: 'Hello from Optimized Docker Multi-stage Build!'
    });
});

app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});
