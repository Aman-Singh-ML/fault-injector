from fastapi import FastAPI, HTTPException, Header, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from typing import Optional
import uvicorn

from app.db.postgres import init_db
from app.api.routes import booking, admin

app = FastAPI(
    title="Booking Service",
    description="Hotel Booking Management Service",
    version="1.0.0"
)

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    body = await request.body()
    print(f"❌ Validation Error on {request.url}")
    print(f"❌ Errors: {exc.errors()}")
    print(f"❌ Request body: {body.decode()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors()},
    )

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database
@app.on_event("startup")
async def startup_event():
    await init_db()

# Health check
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "booking-service"}

# Include routers
app.include_router(booking.router, prefix="/bookings", tags=["bookings"])
app.include_router(admin.router, prefix="/admin", tags=["admin"])

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)

