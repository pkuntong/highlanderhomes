import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useTouchGestures } from '@/hooks/use-touch-gestures';

const navigationOrder = [
  '/dashboard',
  '/properties',
  '/tenants',
  '/rent-tracking',
  '/maintenance',
  '/documents',
  '/calendar',
  '/reminders',
  '/analytics',
  '/profile'
];

export function SwipeNavigation({ children, disabled = false }) {
  const navigate = useNavigate();
  const location = useLocation();

  const currentIndex = navigationOrder.indexOf(location.pathname);

  const handleSwipeLeft = () => {
    if (disabled || currentIndex === -1) return;
    const nextIndex = (currentIndex + 1) % navigationOrder.length;
    navigate(navigationOrder[nextIndex]);
  };

  const handleSwipeRight = () => {
    if (disabled || currentIndex === -1) return;
    const prevIndex = currentIndex === 0 ? navigationOrder.length - 1 : currentIndex - 1;
    navigate(navigationOrder[prevIndex]);
  };

  const { touchHandlers } = useTouchGestures({
    onSwipeLeft: handleSwipeLeft,
    onSwipeRight: handleSwipeRight,
    threshold: 100
  });

  return (
    <div {...touchHandlers} className="h-full w-full">
      {children}
    </div>
  );
}

export function SwipeIndicator({ direction, children }) {
  return (
    <div className="relative overflow-hidden">
      <div className={`transition-transform duration-200 ${
        direction === 'left' ? '-translate-x-2' : 
        direction === 'right' ? 'translate-x-2' : ''
      }`}>
        {children}
      </div>
    </div>
  );
}