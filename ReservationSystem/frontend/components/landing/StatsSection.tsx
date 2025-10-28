'use client';

export function StatsSection() {
  return (
    <div className="mt-20 bg-white rounded-lg shadow-xl p-8">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-8 text-center">
        <div>
          <div className="text-4xl font-bold text-primary-600 mb-2">10K+</div>
          <div className="text-gray-600">Hotels</div>
        </div>
        <div>
          <div className="text-4xl font-bold text-primary-600 mb-2">500+</div>
          <div className="text-gray-600">Cities</div>
        </div>
        <div>
          <div className="text-4xl font-bold text-primary-600 mb-2">1M+</div>
          <div className="text-gray-600">Happy Customers</div>
        </div>
        <div>
          <div className="text-4xl font-bold text-primary-600 mb-2">4.8/5</div>
          <div className="text-gray-600">Average Rating</div>
        </div>
      </div>
    </div>
  );
}

