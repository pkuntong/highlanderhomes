import React from 'react';
import { RefreshCw, ArrowDown } from 'lucide-react';
import { usePullToRefresh } from '@/hooks/use-touch-gestures';
import { cn } from '@/lib/utils';

export function PullToRefresh({ onRefresh, children, disabled = false }) {
  const { pullToRefreshHandlers, isPulling, pullDistance, isRefreshing } = usePullToRefresh(
    disabled ? undefined : onRefresh,
    80
  );

  const opacity = Math.min(pullDistance / 80, 1);
  const scale = Math.min(0.8 + (pullDistance / 80) * 0.2, 1);

  return (
    <div className="relative">
      {/* Pull indicator */}
      <div 
        className={cn(
          "absolute top-0 left-1/2 transform -translate-x-1/2 transition-all duration-200 z-10",
          "flex items-center justify-center w-12 h-12 rounded-full bg-primary/10 backdrop-blur-sm",
          isPulling ? "opacity-100" : "opacity-0"
        )}
        style={{
          transform: `translateX(-50%) translateY(${Math.min(pullDistance - 40, 20)}px) scale(${scale})`,
          opacity: opacity
        }}
      >
        {isRefreshing ? (
          <RefreshCw className="w-5 h-5 text-primary animate-spin" />
        ) : (
          <ArrowDown 
            className={cn(
              "w-5 h-5 text-primary transition-transform duration-200",
              pullDistance >= 80 && "rotate-180"
            )} 
          />
        )}
      </div>

      {/* Content */}
      <div 
        {...pullToRefreshHandlers}
        className="relative"
        style={{
          transform: `translateY(${isPulling ? Math.min(pullDistance * 0.5, 40) : 0}px)`,
          transition: isPulling ? 'none' : 'transform 0.3s ease-out'
        }}
      >
        {children}
      </div>
    </div>
  );
}