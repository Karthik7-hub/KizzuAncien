require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const morgan = require('morgan');
const mongoose = require('mongoose');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const friendRoutes = require('./routes/friendRoutes');
const challengeRoutes = require('./routes/challengeRoutes');
const truthDareRoutes = require('./routes/truthDareRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const { errorHandler } = require('./middleware/errorMiddleware');

const app = express();
const PORT = process.env.PORT || 5000;
const isProduction = process.env.NODE_ENV === 'production';

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many requests from this IP, please try again after 15 minutes'
});

// Middleware
app.use(helmet({
  contentSecurityPolicy: isProduction ? undefined : false
}));
app.use(limiter);
app.use(compression());
app.use(cors({
  origin: isProduction ? process.env.CLIENT_URL : true,
  credentials: true
}));
app.use(express.json());

if (!isProduction) {
  app.use(morgan('dev'));
  // Development-only request logger
  app.use((req, res, next) => {
    console.log(`📩 [${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
    next();
  });
}

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/friends', friendRoutes);
app.use('/api/challenges', challengeRoutes);
app.use('/api/truth-dare', truthDareRoutes);
app.use('/api/notifications', notificationRoutes);

app.get('/', (req, res) => res.json({ status: 'KizzuAncien API' }));

app.use(errorHandler);

// Database connection & Server Start
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    if (!isProduction) console.log('✅ MongoDB Connected');
    app.listen(PORT, '0.0.0.0', () => {
      if (!isProduction) {
        console.log(`🚀 Server running at: http://localhost:${PORT}`);
      }
    });
  })
  .catch(err => {
    console.error('❌ MongoDB Connection Error:', err.message);
    process.exit(1);
  });
