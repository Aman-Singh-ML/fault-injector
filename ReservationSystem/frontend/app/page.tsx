'use client';

import { useAuthStore } from '@/store/authStore';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { LandingNavbar } from '@/components/landing/LandingNavbar';
import { HeroSection } from '@/components/landing/HeroSection';
import { FeaturesSection } from '@/components/landing/FeaturesSection';
import { StatsSection } from '@/components/landing/StatsSection';
import { CTASection } from '@/components/landing/CTASection';
import { LandingFooter } from '@/components/landing/LandingFooter';

export default function HomePage() {
  const router = useRouter();
  const { isAuthenticated } = useAuthStore();

  useEffect(() => {
    if (isAuthenticated) {
      router.push('/dashboard');
    }
  }, [isAuthenticated, router]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-white">
      <LandingNavbar />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <HeroSection />
        <FeaturesSection />
        <StatsSection />
        <CTASection />
      </div>

      <LandingFooter />
    </div>
  );
}

