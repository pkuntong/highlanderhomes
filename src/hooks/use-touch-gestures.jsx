import { useCallback, useRef, useState } from 'react';

export function useTouchGestures({
  onSwipeLeft,
  onSwipeRight,
  onSwipeUp,
  onSwipeDown,
  threshold = 50,
  preventScroll = false
}) {
  const touchStartRef = useRef(null);
  const touchEndRef = useRef(null);
  const [isDragging, setIsDragging] = useState(false);

  const handleTouchStart = useCallback((e) => {
    setIsDragging(true);
    touchStartRef.current = {
      x: e.touches[0].clientX,
      y: e.touches[0].clientY,
      time: Date.now()
    };
    if (preventScroll) {
      e.preventDefault();
    }
  }, [preventScroll]);

  const handleTouchMove = useCallback((e) => {
    if (!isDragging || !touchStartRef.current) return;
    
    if (preventScroll) {
      e.preventDefault();
    }
  }, [isDragging, preventScroll]);

  const handleTouchEnd = useCallback((e) => {
    if (!touchStartRef.current) return;
    
    setIsDragging(false);
    touchEndRef.current = {
      x: e.changedTouches[0].clientX,
      y: e.changedTouches[0].clientY,
      time: Date.now()
    };

    const deltaX = touchEndRef.current.x - touchStartRef.current.x;
    const deltaY = touchEndRef.current.y - touchStartRef.current.y;
    const deltaTime = touchEndRef.current.time - touchStartRef.current.time;
    
    // Only trigger swipe if it's fast enough (under 500ms) and long enough
    if (deltaTime > 500) return;
    
    const absX = Math.abs(deltaX);
    const absY = Math.abs(deltaY);
    
    // Horizontal swipe
    if (absX > absY && absX > threshold) {
      if (deltaX > 0) {
        onSwipeRight?.();
      } else {
        onSwipeLeft?.();
      }
    }
    // Vertical swipe
    else if (absY > absX && absY > threshold) {
      if (deltaY > 0) {
        onSwipeDown?.();
      } else {
        onSwipeUp?.();
      }
    }
    
    touchStartRef.current = null;
    touchEndRef.current = null;
  }, [onSwipeLeft, onSwipeRight, onSwipeUp, onSwipeDown, threshold]);

  return {
    touchHandlers: {
      onTouchStart: handleTouchStart,
      onTouchMove: handleTouchMove,
      onTouchEnd: handleTouchEnd,
    },
    isDragging
  };
}

export function usePullToRefresh(onRefresh, threshold = 100) {
  const [isPulling, setIsPulling] = useState(false);
  const [pullDistance, setPullDistance] = useState(0);
  const startY = useRef(0);
  const currentY = useRef(0);

  const handleTouchStart = useCallback((e) => {
    startY.current = e.touches[0].clientY;
    setIsPulling(false);
    setPullDistance(0);
  }, []);

  const handleTouchMove = useCallback((e) => {
    currentY.current = e.touches[0].clientY;
    const distance = currentY.current - startY.current;
    
    // Only allow pull down at the top of the page
    if (window.scrollY === 0 && distance > 0) {
      setIsPulling(true);
      setPullDistance(Math.min(distance, threshold * 1.5));
      e.preventDefault();
    }
  }, [threshold]);

  const handleTouchEnd = useCallback(() => {
    if (isPulling && pullDistance >= threshold) {
      onRefresh?.();
    }
    setIsPulling(false);
    setPullDistance(0);
    startY.current = 0;
    currentY.current = 0;
  }, [isPulling, pullDistance, threshold, onRefresh]);

  return {
    pullToRefreshHandlers: {
      onTouchStart: handleTouchStart,
      onTouchMove: handleTouchMove,
      onTouchEnd: handleTouchEnd,
    },
    isPulling,
    pullDistance,
    isRefreshing: isPulling && pullDistance >= threshold
  };
}