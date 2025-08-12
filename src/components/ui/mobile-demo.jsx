import React, { useState } from 'react';
import { PullToRefresh } from './pull-to-refresh';
import { TouchableCard, TouchableButton, MobileGrid, MobileStack } from './mobile-touch';
import { FadeIn, StaggeredGrid, FloatingActionButton } from './mobile-animations';
import { Plus, Refresh } from 'lucide-react';

export function MobileOptimizedList({ 
  items = [], 
  onRefresh, 
  renderItem, 
  showFAB = true,
  onAdd,
  isLoading = false 
}) {
  const [refreshing, setRefreshing] = useState(false);

  const handleRefresh = async () => {
    if (onRefresh && !refreshing) {
      setRefreshing(true);
      try {
        await onRefresh();
      } finally {
        setRefreshing(false);
      }
    }
  };

  if (isLoading) {
    return (
      <MobileStack>
        {[...Array(6)].map((_, i) => (
          <div key={i} className="h-24 bg-muted rounded-lg animate-pulse" />
        ))}
      </MobileStack>
    );
  }

  return (
    <>
      <PullToRefresh onRefresh={handleRefresh} disabled={refreshing}>
        <StaggeredGrid className="gap-3 sm:gap-4">
          {items.map((item, index) => (
            <FadeIn key={item.id || index} delay={index * 50}>
              {renderItem(item, index)}
            </FadeIn>
          ))}
        </StaggeredGrid>
      </PullToRefresh>

      {showFAB && onAdd && (
        <FloatingActionButton onClick={onAdd} position="bottom-right">
          <Plus className="w-6 h-6" />
        </FloatingActionButton>
      )}
    </>
  );
}

export function MobilePropertyCard({ 
  property, 
  onEdit, 
  onDelete,
  className 
}) {
  return (
    <TouchableCard 
      className={`p-4 space-y-3 ${className}`}
      onClick={() => onEdit?.(property)}
    >
      <div className="flex justify-between items-start">
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold truncate text-base sm:text-lg">
            {property.address}
          </h3>
          <p className="text-sm text-muted-foreground truncate">
            {property.city}, {property.state} {property.zipCode}
          </p>
        </div>
        <div className="flex flex-col items-end ml-2">
          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
            property.status === 'occupied' 
              ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
              : property.status === 'vacant'
              ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
              : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
          }`}>
            {property.status}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 text-sm">
        <div>
          <span className="font-medium">Rent:</span>
          <span className="ml-1">${property.monthlyRent || '0'}</span>
        </div>
        <div>
          <span className="font-medium">Bedrooms:</span>
          <span className="ml-1">{property.bedrooms || 'N/A'}</span>
        </div>
      </div>

      <div className="flex gap-2 pt-2 border-t">
        <TouchableButton
          variant="outline"
          size="sm"
          className="flex-1"
          onClick={(e) => {
            e.stopPropagation();
            onEdit?.(property);
          }}
        >
          Edit
        </TouchableButton>
        <TouchableButton
          variant="destructive"
          size="sm"
          className="flex-1"
          onClick={(e) => {
            e.stopPropagation();
            onDelete?.(property);
          }}
        >
          Delete
        </TouchableButton>
      </div>
    </TouchableCard>
  );
}

export function MobileSearchAndFilter({ 
  searchTerm, 
  onSearchChange,
  statusFilter,
  onStatusFilterChange,
  placeholder = "Search...",
  className 
}) {
  return (
    <MobileStack spacing="tight" className={className}>
      <input
        type="text"
        placeholder={placeholder}
        value={searchTerm}
        onChange={(e) => onSearchChange(e.target.value)}
        className="flex h-12 w-full rounded-md border border-input bg-background px-3 py-2 text-base ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 touch-manipulation"
      />
      
      <div className="flex gap-2 overflow-x-auto pb-2">
        {['all', 'occupied', 'vacant', 'maintenance'].map((status) => (
          <TouchableButton
            key={status}
            variant={statusFilter === status ? 'default' : 'outline'}
            size="sm"
            className="whitespace-nowrap min-w-fit"
            onClick={() => onStatusFilterChange(status)}
          >
            {status.charAt(0).toUpperCase() + status.slice(1)}
          </TouchableButton>
        ))}
      </div>
    </MobileStack>
  );
}