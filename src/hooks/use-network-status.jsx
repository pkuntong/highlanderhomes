import { useState, useEffect } from 'react';

export function useNetworkStatus() {
  const [isOnline, setIsOnline] = useState(typeof navigator !== 'undefined' ? navigator.onLine : true);
  const [networkInfo, setNetworkInfo] = useState({
    effectiveType: '4g',
    downlink: 10,
    rtt: 100
  });

  useEffect(() => {
    function handleOnline() {
      setIsOnline(true);
    }

    function handleOffline() {
      setIsOnline(false);
    }

    function handleNetworkChange() {
      if ('connection' in navigator) {
        const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
        setNetworkInfo({
          effectiveType: connection.effectiveType || '4g',
          downlink: connection.downlink || 10,
          rtt: connection.rtt || 100
        });
      }
    }

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    if ('connection' in navigator) {
      const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
      connection.addEventListener('change', handleNetworkChange);
      handleNetworkChange(); // Initial call
    }

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
      if ('connection' in navigator) {
        const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
        connection.removeEventListener('change', handleNetworkChange);
      }
    };
  }, []);

  return {
    isOnline,
    ...networkInfo,
    isSlowNetwork: networkInfo.effectiveType === 'slow-2g' || networkInfo.effectiveType === '2g'
  };
}