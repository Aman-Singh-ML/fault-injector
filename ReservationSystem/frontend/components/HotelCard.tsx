'use client';

import { Hotel } from '@/types';
import { useRouter } from 'next/navigation';
import { FaStar, FaMapMarkerAlt, FaDollarSign } from 'react-icons/fa';

interface HotelCardProps {
  hotel: Hotel;
}

export default function HotelCard({ hotel }: HotelCardProps) {
  const router = useRouter();

  const handleViewDetails = () => {
    router.push(`/hotels/${hotel._id}`);
  };

  const handleBookNow = (e: React.MouseEvent) => {
    e.stopPropagation();
    router.push(`/hotels/${hotel._id}`);
  };

  return (
    <div
      onClick={handleViewDetails}
      className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-xl transition-shadow duration-300 cursor-pointer"
    >
      {/* Hotel Image */}
      <div className="relative h-48 bg-gray-200">
        {hotel.images && hotel.images.length > 0 ? (
          <img
            src={hotel.images[0]}
            alt={hotel.name}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-primary-100 to-primary-200">
            <span className="text-primary-600 text-4xl font-bold">
              {hotel.name.charAt(0)}
            </span>
          </div>
        )}
        
        {/* Rating Badge */}
        <div className="absolute top-2 right-2 bg-white px-2 py-1 rounded-md shadow-md flex items-center space-x-1">
          <FaStar className="text-yellow-400" />
          <span className="font-semibold text-sm text-gray-900">{hotel.rating.toFixed(1)}</span>
        </div>
      </div>

      {/* Hotel Info */}
      <div className="p-4">
        <h3 className="text-lg font-bold text-gray-900 mb-2 truncate">
          {hotel.name}
        </h3>
        
        <div className="flex items-center text-gray-600 text-sm mb-2">
          <FaMapMarkerAlt className="mr-1" />
          <span className="truncate">{hotel.city}, {hotel.address}</span>
        </div>

        <p className="text-gray-600 text-sm mb-4 line-clamp-2">
          {hotel.description}
        </p>

        {/* Amenities */}
        {hotel.amenities && hotel.amenities.length > 0 && (
          <div className="flex flex-wrap gap-1 mb-4">
            {hotel.amenities.slice(0, 3).map((amenity, index) => (
              <span
                key={index}
                className="px-2 py-1 bg-primary-50 text-primary-700 text-xs rounded-full"
              >
                {amenity}
              </span>
            ))}
            {hotel.amenities.length > 3 && (
              <span className="px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded-full">
                +{hotel.amenities.length - 3} more
              </span>
            )}
          </div>
        )}

        {/* Price and Book Button */}
        <div className="flex items-center justify-between pt-4 border-t border-gray-200">
          <div>
            <div className="flex items-center text-primary-600 font-bold text-xl">
              <FaDollarSign className="text-lg" />
              <span>{hotel.price_per_night}</span>
            </div>
            <span className="text-gray-500 text-xs">per night</span>
          </div>
          
          <button
            onClick={handleBookNow}
            className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors duration-200 text-sm font-medium"
          >
            Book Now
          </button>
        </div>

        {/* Availability */}
        <div className="mt-2 text-xs text-gray-500">
          {hotel.available_rooms > 0 ? (
            <span className="text-green-600">
              {hotel.available_rooms} rooms available
            </span>
          ) : (
            <span className="text-red-600">No rooms available</span>
          )}
        </div>
      </div>
    </div>
  );
}

