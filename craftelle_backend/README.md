# 🌹 Craftelle Mobile App

A full‑stack **mobile commerce application** built for **Craftelle Rose GH**, a Ghana‑based premium gifting brand specializing in handcrafted satin rose bouquets and luxury gift arrangements.

This repository contains the **Flutter mobile app** and integrates with a **NestJS backend API** to provide a smooth ordering and management experience for customers and administrators.

Before diving into features, here is an overview of the project, its architecture, and setup instructions.

---

## 🛠 Tech Stack

### Frontend (Mobile)

* **Flutter**
* Dart
* Provider / Riverpod / Bloc (depending on setup)
* REST API integration

### Backend (NestJS)

* **NestJS**
* TypeScript
* PostgreSQL / MongoDB (depending on configuration)
* JWT Authentication

---

## 📁 Project Structure

```
craftelle_frontend/
│
├── frontend/                # Flutter mobile application
│   ├── lib/
│   ├── assets/
│   └── pubspec.yaml
│
├── craftelle_backend/               # NestJS backend API
│   ├── src/
│   ├── prisma/ | models/
│   └── package.json
│
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK
* Node.js (v18+ recommended)
* npm or yarn
* Git

### Running the Mobile App (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

### Running the Backend (NestJS)

```bash
cd backend
npm install
npm run start:dev
```

The backend will typically run on:

```
http://localhost:3000
```

### Environment Variables

Create a `.env` file in the backend directory:

```env
PORT=3000
JWT_SECRET=your_secret_key
DATABASE_URL=your_database_url
```

---

## 🎨 Branding & Design

* Elegant typography
* Rose / pink gradient accents
* Minimal, luxury‑inspired layout

---

## 📦 Deployment

* **Mobile App**: Android & iOS (Play Store / App Store)
* **Backend**: FlyIO

---

## 🤝 Contributing

1. Fork the repository
2. Create a new branch (`feature/your-feature-name`)
3. Commit your changes
4. Open a pull request

---

## 📄 License

This project is proprietary and built exclusively for **Craftelle Rose GH**.

---

## 📞 About Craftelle

**Craftelle Rose GH** creates handcrafted satin roses that bloom forever — perfect for gifts, décor, and memorable moments.

🌐 Website: [https://www.craftellerosegh.com/](https://www.craftellerosegh.com/)

---

## ✨ Features Implemented

Below is a list of features currently implemented in the mobile app and backend:

### 📱 Mobile App (Flutter)

* User authentication (Sign up / Login)
* Browse satin rose bouquets and gift items
* View product details (images, descriptions, prices)
* Place and track orders
* Custom bouquet requests
* In‑app notifications (order updates)
* Clean, elegant UI inspired by Craftelle’s brand aesthetic

### 🧠 Backend (NestJS)

* RESTful API
* User authentication & authorization (JWT)
* Product & category management
* Order management
* Admin endpoints
* Secure data handling

---

## 📝 Full Planned Features

### 1. Home / Landing Screen

* Hero section with “Eternal Elegance” message
* Featured collections
* Order Now button
* WhatsApp quick chat button
* Social proof (Instagram feed or testimonials)

### 2. Product & Collection Catalog

* Categories: Radiance Box, Classic Touch, Bobo Balloon, Room Decor, Engagement Wrapping, Cute Touch, etc.
* High-quality images
* Price ranges
* Short descriptions
* Tags (Romantic, Proposal, Birthday, Anniversary)

### 3. Product Detail Page

* Image gallery
* Description & materials
* Starting price
* Color options (custom colors)
* Add-ons (balloons, notes, wrapping)
* Customize button
* Order via WhatsApp fallback

### 4. Custom Order Builder

* Choose collection
* Select colors
* Size options
* Occasion type
* Special notes
* Upload inspiration image
* Live price estimate (optional)

### 5. Order & Checkout

* Customer details form
* Delivery location
* Delivery time selection
* Payment methods: Mobile Money (MTN, Vodafone, AirtelTigo)
* Partial or full payment
* Order confirmation screen
* WhatsApp order summary auto-send

### 6. Delivery & Tracking

* Delivery window display
* Delivery status: Preparing, Out for delivery, Delivered
* Location-based delivery fee calculation

### 7. User Account

* Order history
* Saved addresses
* Favorite products
* Re-order feature
* Profile management

### 8. WhatsApp Integration

* Floating WhatsApp button
* Auto-filled messages for quick orders
* Order follow-ups via WhatsApp

### 9. Notifications

* Order confirmation
* Delivery updates
* New collections

### 10. Reviews & Testimonials

* Customer ratings
* Photo reviews
* Instagram-style social proof

### 11. Gallery / Inspiration Feed

* Real customer deliveries
* Before/after room decor
* Engagement setups
* Shareable images

### 12. Social Media Integration

* Instagram feed
* TikTok previews
* Share products to social media

### 13. Admin Dashboard

* Manage products & prices
* Update availability
* View orders
* Change order status
* Delivery assignment
* Customer messages

### 14. Inventory & Capacity Management

* Track materials (satin colors, boxes)
* Limit daily bookings for room decor
* Prevent overbooking

### 15. Analytics

* Most ordered collections
* Peak order times
* Delivery locations heatmap
* Repeat customers

### 16. Location Support

* Ashaiman
* Tamale

### 17. About Craftelle

* Brand story, journey, and value for money
* Why Craftelle is the choice for lasting gifts

### 18. Payments

* Payment confirmation before production
* Full payment support
* Partial payment options

### 19. User Roles

* Customer
* Seller
* Admin
* Analyst

### 20. Operations & Extras

* Test user and delivery personnel for trial periods
* Personalized notes
* Room décor services
* Accept or reject custom requests

---

Built with ❤️ using **Flutter** and **NestJS**.