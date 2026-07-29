const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { MongoClient } = require('mongodb');
const redis = require('redis');

const app = express();
app.use(bodyParser.json());
app.use(cors());

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/product_catalog';
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

let dbClient;
let productsCollection;
let redisClient;

// Default products to seed the database if empty
const defaultProducts = [
  {
    id: 1,
    name: 'Wireless Bluetooth Headphones',
    description: 'High-quality sound and comfortable fit',
    price: 59.99,
    category: 'Electronics',
  },
  {
    id: 2,
    name: 'Vintage Leather Backpack',
    description: 'Stylish and durable backpack for everyday use',
    price: 89.99,
    category: 'Accessories',
  },
  {
    id: 3,
    name: 'Stainless Steel Water Bottle',
    description: 'Eco-friendly and leak-proof water bottle',
    price: 19.99,
    category: 'Home & Kitchen',
  },
  {
    id: 4,
    name: 'Organic Green Tea',
    description: 'A refreshing and healthy organic green tea',
    price: 15.99,
    category: 'Groceries',
  },
  {
    id: 5,
    name: 'Smartwatch Fitness Tracker',
    description: 'Track your fitness and stay connected on the go',
    price: 199.99,
    category: 'Electronics',
  },
  {
    id: 6,
    name: 'Professional Studio Microphone',
    description: 'Record high-quality audio with this studio microphone',
    price: 129.99,
    category: 'Electronics',
  },
  {
    id: 7,
    name: 'Ergonomic Office Chair',
    description: 'Stay comfortable while working with this ergonomic chair',
    price: 249.99,
    category: 'Office Supplies',
  },
  {
    id: 8,
    name: 'LED Desk Lamp',
    description: 'Brighten your workspace with this energy-efficient LED lamp',
    price: 39.99,
    category: 'Home & Kitchen',
  },
  {
    id: 9,
    name: 'Gourmet Chocolate Box',
    description: 'Indulge in a variety of gourmet chocolates',
    price: 29.99,
    category: 'Groceries',
  },
  {
    id: 10,
    name: 'Yoga Mat with Carrying Strap',
    description: 'A non-slip yoga mat perfect for all types of yoga',
    price: 49.99,
    category: 'Fitness',
  },
  {
    id: 11,
    name: 'Insulated Camping Tent',
    description: 'A durable and insulated tent for your outdoor adventures',
    price: 349.99,
    category: 'Outdoor',
  },
  {
    id: 12,
    name: 'Bluetooth Speaker',
    description: 'Portable speaker with exceptional sound quality',
    price: 99.99,
    category: 'Electronics',
  }
];

async function connectDB() {
  try {
    dbClient = new MongoClient(MONGODB_URI);
    await dbClient.connect();
    const db = dbClient.db();
    productsCollection = db.collection('products');
    console.log('Connected to MongoDB database');

    // Seed data if empty
    const count = await productsCollection.countDocuments();
    if (count === 0) {
      await productsCollection.insertMany(defaultProducts);
      console.log('Seeded database with default products');
    }
  } catch (error) {
    console.error('Failed to connect to MongoDB:', error);
  }
}

async function connectRedis() {
  try {
    redisClient = redis.createClient({ url: REDIS_URL });
    redisClient.on('error', (err) => console.error('Redis Client Error', err));
    await redisClient.connect();
    console.log('Connected to Redis server');
  } catch (error) {
    console.error('Failed to connect to Redis:', error);
  }
}

// Get all products
app.get('/api/products', async (req, res) => {
  try {
    // 1. Try serving from Redis cache
    if (redisClient && redisClient.isOpen) {
      try {
        const cachedCatalog = await redisClient.get('catalog:all');
        if (cachedCatalog) {
          console.log('Serving catalog from Redis cache');
          return res.json(JSON.parse(cachedCatalog));
        }
      } catch (cacheError) {
        console.error('Redis get error:', cacheError);
      }
    }

    // 2. Fetch from MongoDB database
    if (!productsCollection) {
      return res.status(500).json({ error: 'Database connection not established' });
    }
    const products = await productsCollection.find({}).project({ _id: 0 }).toArray();
    console.log('Serving catalog from MongoDB');

    // 3. Cache the catalog in Redis (TTL: 5 minutes / 300 seconds)
    if (redisClient && redisClient.isOpen) {
      try {
        await redisClient.setEx('catalog:all', 300, JSON.stringify(products));
      } catch (cacheError) {
        console.error('Redis set error:', cacheError);
      }
    }

    res.json(products);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: 'Error fetching products' });
  }
});

// Get a single product by ID
app.get('/api/products/:id', async (req, res) => {
  try {
    const productId = parseInt(req.params.id);
    const cacheKey = `product:id:${productId}`;

    // 1. Try serving from Redis cache
    if (redisClient && redisClient.isOpen) {
      try {
        const cachedProduct = await redisClient.get(cacheKey);
        if (cachedProduct) {
          console.log(`Serving product ${productId} from Redis cache`);
          return res.json(JSON.parse(cachedProduct));
        }
      } catch (cacheError) {
        console.error('Redis get error:', cacheError);
      }
    }

    // 2. Fetch from MongoDB database
    if (!productsCollection) {
      return res.status(500).json({ error: 'Database connection not established' });
    }
    const product = await productsCollection.findOne({ id: productId }, { projection: { _id: 0 } });

    if (product) {
      console.log(`Serving product ${productId} from MongoDB`);
      // 3. Cache the product details in Redis (TTL: 5 minutes / 300 seconds)
      if (redisClient && redisClient.isOpen) {
        try {
          await redisClient.setEx(cacheKey, 300, JSON.stringify(product));
        } catch (cacheError) {
          console.error('Redis set error:', cacheError);
        }
      }
      res.json(product);
    } else {
      res.status(404).json({ error: 'Product not found' });
    }
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ error: 'Error fetching product' });
  }
});

// Start the server
const port = process.env.PORT || 3001;
async function startServer() {
  await connectDB();
  await connectRedis();
  app.listen(port, () => {
    console.log(`Product Catalog microservice is running on port ${port}`);
  });
}

startServer();