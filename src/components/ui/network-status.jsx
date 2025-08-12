import React from 'react';
import { Wifi, WifiOff, Zap } from 'lucide-react';
import { useNetworkStatus } from '@/hooks/use-network-status';
import { cn } from '@/lib/utils';

export function NetworkStatusIndicator({ className }) {
  const { isOnline, effectiveType, isSlowNetwork } = useNetworkStatus();

  if (isOnline && !isSlowNetwork) {
    return null; // Don't show anything when connection is good
  }

  return (
    <div className={cn(
      'fixed top-20 left-4 right-4 z-50 mx-auto max-w-sm',
      'bg-background/90 backdrop-blur-sm border rounded-lg p-3 shadow-lg',
      'flex items-center gap-2 text-sm',
      className
    )}>
      {isOnline ? (
        <>
          <Zap className="w-4 h-4 text-orange-500" />
          <span className="text-orange-700 dark:text-orange-300">
            Slow connection ({effectiveType})
          </span>
        </>
      ) : (
        <>
          <WifiOff className="w-4 h-4 text-red-500" />
          <span className="text-red-700 dark:text-red-300">
            No internet connection
          </span>
        </>
      )}
    </div>
  );
}

export function OfflineBanner() {
  const { isOnline } = useNetworkStatus();

  if (isOnline) return null;

  return (
    <div className="bg-red-500 text-white p-2 text-center text-sm">
      <WifiOff className="w-4 h-4 inline mr-2" />
      You're offline. Some features may not be available.
    </div>
  );
}