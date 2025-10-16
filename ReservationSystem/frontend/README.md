# Hotel Reservation System - Frontend

A modern, responsive Next.js frontend for the Hotel Reservation System with separate user and admin interfaces.

## 🚀 Features

### User Features
- **Authentication**: Login and registration with JWT tokens
- **Hotel Search**: Advanced search with filters (city, dates, guests, price range, rating)
- **Dashboard**: Browse available hotels with beautiful cards
- **Reservations**: View and manage bookings
- **Notifications**: Real-time notifications for booking updates
- **Profile Management**: Update personal information

### Admin Features
- **Admin Dashboard**: Analytics and system overview
- **User Management**: View, edit, and delete users
- **Hotel Management**: CRUD operations for hotels
- **Booking Management**: View and update booking statuses

## 🛠️ Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State Management**: Zustand with persist middleware
- **HTTP Client**: Axios
- **Icons**: React Icons
- **Notifications**: React Hot Toast
- **Date Handling**: date-fns

## 📁 Project Structure

```
frontend-nextjs/
├── app/                      # Next.js App Router pages
│   ├── about/               # About page
│   ├── admin/               # Admin section
│   │   ├── bookings/        # Manage bookings
│   │   ├── hotels/          # Manage hotels
│   │   └── users/           # Manage users
│   ├── dashboard/           # User dashboard
│   ├── login/               # Login page
│   ├── notifications/       # Notifications page
│   ├── profile/             # User profile
│   ├── register/            # Registration page
│   ├── reservations/        # User reservations
│   ├── search/              # Advanced search page
│   ├── layout.tsx           # Root layout
│   ├── globals.css          # Global styles
│   └── page.tsx             # Home/landing page
├── components/              # Reusable components
│   ├── HotelCard.tsx        # Hotel display card
│   ├── Navbar.tsx           # Navigation bar
│   └── SearchBar.tsx        # Search component
├── lib/                     # Utilities
│   └── api.ts               # API client and functions
├── store/                   # State management
│   └── authStore.ts         # Authentication store
├── types/                   # TypeScript types
│   └── index.ts             # Type definitions
├── .env.local               # Environment variables
├── next.config.js           # Next.js configuration
├── package.json             # Dependencies
├── tailwind.config.ts       # Tailwind configuration
└── tsconfig.json            # TypeScript configuration
```

## 🔧 Installation

### Prerequisites
- Node.js 18+ and npm/yarn/pnpm
- Backend services running (see main project README)

### Steps

1. **Navigate to the frontend directory**:
   ```bash
   cd frontend-nextjs
   ```

2. **Install dependencies**:
   ```bash
   npm install
   # or
   yarn install
   # or
   pnpm install
   ```

3. **Configure environment variables**:
   
   The `.env.local` file is already created with:
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:9000
   ```
   
   Update if your API Gateway runs on a different port.

4. **Run the development server**:
   ```bash
   npm run dev
   # or
   yarn dev
   # or
   pnpm dev
   ```

5. **Open your browser**:
   Navigate to [http://localhost:3000](http://localhost:3000)

## 📝 Available Scripts

- `npm run dev` - Start development server on port 3000
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## 🔐 Demo Credentials

### Customer Account
- **Email**: test@hotel.com
- **Password**: password123

### Admin Account
- **Email**: admin@hotel.com
- **Password**: password123

## 🎨 Pages Overview

### Public Pages
- **/** - Landing page with features and CTA
- **/login** - User login
- **/register** - User registration
- **/about** - About the platform

### User Pages (Protected)
- **/dashboard** - Browse hotels with quick search
- **/search** - Advanced search with filters
- **/reservations** - View and manage bookings
- **/notifications** - View notifications
- **/profile** - Manage profile

### Admin Pages (Admin Only)
- **/admin** - Admin dashboard with analytics
- **/admin/users** - User management
- **/admin/hotels** - Hotel management
- **/admin/bookings** - Booking management

## 🔌 API Integration

The frontend connects to the backend API Gateway at `http://localhost:9000`.

### API Endpoints Used

**Authentication**:
- `POST /api/auth/login` - User login
- `POST -p/auth/register` - User registration
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update profile

**Hotels**:
- `GET /api/hotels/search` - Search hotels
- `GET /api/hotels/:id` - Get hotel details

**Bookings**:
- `GET /api/bookings` - Get user bookings
- `POST /api/bookings` - Create booking
- `PUT /api/bookings/:id/cancel` - Cancel booking

**Notifications**:
- `GET /api/notifications` - Get notifications
- `PUT /api/notifications/:id/read` - Mark as read
- `PUT /api/notifications/read-all` - Mark all as read

**Admin**:
- `GET /api/admin/users` - Get all users
- `DELETE /api/admin/users/:id` - Delete user
- `GET /api/admin/hotels` - Get all hotels
- `DELETE /api/admin/hotels/:id` - Delete hotel
- `GET /api/admin/bookings` - Get all bookings
- `PUT /api/admin/bookings/:id/status` - Update booking status
- `GET /api/admin/analytics` - Get analytics

## 🎯 Key Features Implementation

### Authentication Flow
1. User logs in via `/login`
2. JWT token stored in localStorage
3. Zustand store manages auth state with persistence
4. Axios interceptor adds token to all requests
5. 401 responses redirect to login

### Role-Based Access
- Navbar shows different links for ADMIN vs CUSTOMER
- Admin routes check user role and redirect if unauthorized
- Admin-only pages: `/admin/*`

### Search & Filters
- Quick search on dashboard
- Advanced search on `/search` with:
  - City filter
  - Date range (check-in/check-out)
  - Number of guests
  - Price range
  - Minimum rating

### Responsive Design
- Mobile-first approach with Tailwind CSS
- Responsive grid layouts
- Mobile menu for navigation
- Optimized for all screen sizes

## 🚀 Deployment

### Build for Production
```bash
npm run build
```

### Start Production Server
```bash
npm run start
```

### Environment Variables for Production
Update `.env.local` or set environment variables:
```env
NEXT_PUBLIC_API_URL=https://your-api-domain.com
```

## 🐛 Troubleshooting

### API Connection Issues
- Ensure backend services are running
- Check API Gateway is accessible at `http://localhost:9000`
- Verify CORS is configured on backend

### Authentication Issues
- Clear localStorage and try logging in again
- Check JWT token expiration
- Verify backend auth service is running

### Build Errors
- Delete `.next` folder and `node_modules`
- Run `npm install` again
- Check for TypeScript errors with `npm run lint`

## 📚 Additional Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Zustand Documentation](https://github.com/pmndrs/zustand)
- [React Icons](https://react-icons.github.io/react-icons/)

## 🤝 Contributing

1. Follow the existing code structure
2. Use TypeScript for type safety
3. Follow Tailwind CSS conventions
4. Test on multiple screen sizes
5. Ensure admin and user flows work correctly

## 📄 License

This project is part of the Hotel Reservation System.

