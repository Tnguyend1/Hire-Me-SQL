import '../models/problem.dart';

const List<Problem> mockProblems = [
  Problem(
    id: 'p1',
    title: 'Top Selling Products',
    topic: 'JOINs',
    company: 'Amazon',
    difficulty: 'Medium',
    xp: 30,
    statement: 'Find top 5 selling products by total revenue.',
    hint: 'Use JOIN, SUM, GROUP BY, ORDER BY, LIMIT.',
    explanation: 'Join tables, calculate revenue, group and sort.',
    concepts: ['JOIN', 'SUM', 'GROUP BY'],
    acceptedAnswers: [
      'SELECT p.product_name, SUM(s.quantity * s.price) FROM products p JOIN sales s ON p.product_id = s.product_id GROUP BY p.product_name ORDER BY SUM(s.quantity * s.price) DESC LIMIT 5',
    ],
  ),
  Problem(
    id: 'p2',
    title: 'Customers With No Orders',
    topic: 'JOINs',
    company: 'Shopify',
    difficulty: 'Easy',
    xp: 20,
    statement: 'Find customers with no orders.',
    hint: 'LEFT JOIN + NULL',
    explanation: 'LEFT JOIN keeps all customers.',
    concepts: ['LEFT JOIN'],
    acceptedAnswers: [
      'SELECT c.customer_id FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id WHERE o.order_id IS NULL',
    ]
  ),
  Problem(
    id: 'p3',
    title: 'Average Order Value',
    topic: 'Aggregates',
    company: 'Instacart',
    difficulty: 'Easy',
    xp: 20,
    statement: 'Find average order value.',
    hint: 'Use AVG',
    explanation: 'AVG calculates mean.',
    concepts: ['AVG'],
    acceptedAnswers: [
      'SELECT AVG(total_amount) FROM orders',
    ],
  ),
];