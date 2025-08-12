import React, { useState, useEffect } from 'react';
import { cn } from '@/lib/utils';

export function FadeIn({ children, className, delay = 0, duration = 'duration-300' }) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setIsVisible(true), delay);
    return () => clearTimeout(timer);
  }, [delay]);

  return (
    <div
      className={cn(
        'transition-all',
        duration,
        isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4',
        className
      )}
    >
      {children}
    </div>
  );
}

export function SlideIn({ children, className, direction = 'left', delay = 0, duration = 'duration-300' }) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setIsVisible(true), delay);
    return () => clearTimeout(timer);
  }, [delay]);

  const getTransformClasses = () => {
    if (isVisible) return 'translate-x-0 translate-y-0 opacity-100';
    
    switch (direction) {
      case 'left': return '-translate-x-full opacity-0';
      case 'right': return 'translate-x-full opacity-0';
      case 'up': return '-translate-y-full opacity-0';
      case 'down': return 'translate-y-full opacity-0';
      default: return '-translate-x-full opacity-0';
    }
  };

  return (
    <div
      className={cn(
        'transition-all',
        duration,
        getTransformClasses(),
        className
      )}
    >
      {children}
    </div>
  );
}

export function ScaleIn({ children, className, delay = 0, duration = 'duration-300' }) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setIsVisible(true), delay);
    return () => clearTimeout(timer);
  }, [delay]);

  return (
    <div
      className={cn(
        'transition-all',
        duration,
        isVisible ? 'scale-100 opacity-100' : 'scale-95 opacity-0',
        className
      )}
    >
      {children}
    </div>
  );
}

export function StaggeredGrid({ children, className, staggerDelay = 100 }) {
  return (
    <div className={cn('grid gap-4', className)}>
      {React.Children.map(children, (child, index) => (
        <FadeIn key={index} delay={index * staggerDelay}>
          {child}
        </FadeIn>
      ))}
    </div>
  );
}

export function LoadingSpinner({ size = 'default', className }) {
  const sizeClasses = {
    sm: 'w-4 h-4',
    default: 'w-6 h-6',
    lg: 'w-8 h-8',
    xl: 'w-12 h-12'
  };

  return (
    <div
      className={cn(
        'animate-spin rounded-full border-2 border-current border-t-transparent',
        sizeClasses[size],
        className
      )}
    />
  );
}

export function SkeletonLoader({ className, ...props }) {
  return (
    <div
      className={cn(
        'animate-pulse rounded-md bg-muted',
        className
      )}
      {...props}
    />
  );
}

export function PageTransition({ children, className }) {
  return (
    <FadeIn duration="duration-200" className={cn('w-full', className)}>
      {children}
    </FadeIn>
  );
}

export function FloatingActionButton({ 
  children, 
  className, 
  onClick, 
  position = 'bottom-right',
  ...props 
}) {
  const positionClasses = {
    'bottom-right': 'fixed bottom-6 right-6',
    'bottom-left': 'fixed bottom-6 left-6',
    'bottom-center': 'fixed bottom-6 left-1/2 transform -translate-x-1/2',
  };

  return (
    <ScaleIn delay={300}>
      <button
        className={cn(
          'z-50 w-14 h-14 rounded-full bg-primary text-primary-foreground shadow-lg',
          'hover:shadow-xl active:scale-95 transition-all duration-200',
          'flex items-center justify-center touch-manipulation',
          positionClasses[position],
          className
        )}
        onClick={onClick}
        {...props}
      >
        {children}
      </button>
    </ScaleIn>
  );
}