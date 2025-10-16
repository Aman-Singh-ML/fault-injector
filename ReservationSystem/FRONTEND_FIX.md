# Frontend Login/Register Fix

## Issue

The frontend is making requests to `/api/auth/register` instead of `/auth/register`, causing 404 errors.

## Root Cause

The browser is caching an old version of the code or there's a build cache issue.

## Solution

### Step 1: Clear Frontend Cache and Rebuild

```bash
cd frontend

# Stop the dev server (Ctrl+C)

# Clear Next.js cache
rm -rf .next

# Clear node_modules cache (optional but recommended)
rm -rf node_modules/.cache

# Restart dev server
npm run dev
```

### Step 2: Clear Browser Cache

1. Open Chrome DevTools (F12)
2. Right-click on the refresh button
3. Select "Empty Cache and Hard Reload"

OR

1. Open DevTools
2. Go to Application tab
3. Click "Clear storage"
4. Click "Clear site data"

### Step 3: Verify API Endpoints

The API file (`frontend/lib/api.ts`) is already correct:

```typescript
export const authAPI = {
  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),

  register: (data: {
    email: string;
    password: string;
    firstName: string;
    lastName: string;
    phoneNumber: string;
  }) => api.post('/auth/register', data),
  // ...
};
```

✅ Using `/auth/register` (correct)  
❌ NOT using `/api/auth/register`

### Step 4: Test Again

1. Open http://localhost:3000
2. Go to Register page
3. Fill in the form
4. Submit

The request should now go to:
```
http://localhost:9000/auth/register
```

NOT:
```
http://localhost:9000/api/auth/register
```

## Quick Fix Commands

```bash
# Terminal 1: Restart Frontend
cd frontend
rm -rf .next
npm run dev

# Terminal 2: Test the endpoint directly
curl -X POST http://localhost:9000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test2@hotel.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User",
    "phoneNumber": "+1234567890"
  }'
```

## If Still Not Working

### Check Environment Variables

```bash
cd frontend
cat .env.local
```

Should show:
```
NEXT_PUBLIC_API_URL=http://localhost:9000
```

### Check API Base URL in Browser Console

Open browser console and run:
```javascript
console.log(process.env.NEXT_PUBLIC_API_URL)
```

Should output: `http://localhost:9000`

### Verify Services Are Running

```bash
# Check API Gateway
curl http://localhost:9000/health

# Check Auth Service
curl http://localhost:8080/actuator/health
```

Both should return healthy status.

## Expected Behavior

### Registration Request:
```
POST http://localhost:9000/auth/register
Content-Type: application/json

{
  "email": "a@a.com",
  "password": "123456",
  "firstName": "Amrita",
  "lastName": "Kumari",
  "phoneNumber": "9798678022"
}
```

### Expected Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 3,
    "email": "a@a.com",
    "firstName": "Amrita",
    "lastName": "Kumari",
    "role": "CUSTOMER"
  }
}
```

### Login Request:
```
POST http://localhost:9000/auth/login
Content-Type: application/json

{
  "email": "a@a.com",
  "password": "123456"
}
```

### Expected Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 3,
    "email": "a@a.com",
    "firstName": "Amrita",
    "lastName": "Kumari",
    "role": "CUSTOMER"
  }
}
```

## Troubleshooting

### Error: Cannot POST /api/auth/register

**Cause:** Browser is using cached code  
**Fix:** Clear `.next` folder and restart dev server

### Error: Network Error

**Cause:** API Gateway not running  
**Fix:** 
```bash
cd gateway
npm start
```

### Error: 404 Not Found on /auth/register

**Cause:** Auth Service not running  
**Fix:**
```bash
cd mock-auth-service
npm start
```

### Error: CORS

**Cause:** Gateway CORS not configured  
**Fix:** Gateway already has CORS enabled, just restart it

## Summary

The issue is browser/build cache. The fix is:

1. **Stop frontend dev server**
2. **Delete `.next` folder**
3. **Restart dev server**
4. **Hard refresh browser**

Then test registration and login again!

