import * as React from "react"
import { cva } from "class-variance-authority"
import { ChevronDown, ChevronUp, ChevronsUpDown } from "lucide-react"

import { cn } from "@/lib/utils"

const tableVariants = cva(
  "w-full caption-bottom text-sm",
  {
    variants: {
      variant: {
        default: "border-collapse",
        premium: "border-separate border-spacing-0",
        glass: "border-separate border-spacing-0 backdrop-blur-sm",
      }
    },
    defaultVariants: {
      variant: "default"
    }
  }
)

const Table = React.forwardRef(({ className, variant, ...props }, ref) => (
  <div className="relative w-full overflow-auto rounded-xl border border-border-subtle bg-background-elevated/50 backdrop-blur-sm shadow-elevated">
    <table
      ref={ref}
      className={cn(tableVariants({ variant }), className)}
      {...props}
    />
  </div>
))
Table.displayName = "Table"

const TableHeader = React.forwardRef(({ className, ...props }, ref) => (
  <thead 
    ref={ref} 
    className={cn(
      "bg-gradient-to-r from-muted/30 to-muted/10 backdrop-blur-sm [&_tr]:border-b [&_tr]:border-border-subtle",
      className
    )} 
    {...props} 
  />
))
TableHeader.displayName = "TableHeader"

const TableBody = React.forwardRef(({ className, ...props }, ref) => (
  <tbody
    ref={ref}
    className={cn(
      "[&_tr:last-child]:border-0 [&_tr]:transition-all [&_tr]:duration-300",
      className
    )}
    {...props}
  />
))
TableBody.displayName = "TableBody"

const TableFooter = React.forwardRef(({ className, ...props }, ref) => (
  <tfoot
    ref={ref}
    className={cn(
      "border-t border-border-subtle bg-gradient-to-r from-muted/50 to-muted/30 font-semibold backdrop-blur-sm [&>tr]:last:border-b-0",
      className
    )}
    {...props}
  />
))
TableFooter.displayName = "TableFooter"

const TableRow = React.forwardRef(({ className, interactive = true, ...props }, ref) => (
  <tr
    ref={ref}
    className={cn(
      "border-b border-border-subtle transition-all duration-300 group",
      interactive && [
        "hover:bg-accent-premium/30 hover:shadow-sm hover:scale-[1.02]",
        "data-[state=selected]:bg-primary/10 data-[state=selected]:shadow-md"
      ],
      className
    )}
    {...props}
  />
))
TableRow.displayName = "TableRow"

const TableHead = React.forwardRef(({ className, sortable, sortDirection, onSort, ...props }, ref) => (
  <th
    ref={ref}
    className={cn(
      "h-14 px-6 text-left align-middle font-bold text-foreground tracking-wide",
      "[&:has([role=checkbox])]:pr-0",
      sortable && "cursor-pointer hover:bg-muted/50 hover:text-primary transition-all duration-300 select-none",
      className
    )}
    onClick={sortable ? onSort : undefined}
    {...props}
  >
    <div className="flex items-center space-x-2">
      <span>{props.children}</span>
      {sortable && (
        <div className="ml-2">
          {sortDirection === "asc" ? (
            <ChevronUp className="h-4 w-4" />
          ) : sortDirection === "desc" ? (
            <ChevronDown className="h-4 w-4" />
          ) : (
            <ChevronsUpDown className="h-4 w-4 opacity-50" />
          )}
        </div>
      )}
    </div>
  </th>
))
TableHead.displayName = "TableHead"

const TableCell = React.forwardRef(({ className, ...props }, ref) => (
  <td
    ref={ref}
    className={cn(
      "p-6 align-middle text-foreground [&:has([role=checkbox])]:pr-0 group-hover:text-foreground transition-colors duration-300",
      className
    )}
    {...props}
  />
))
TableCell.displayName = "TableCell"

const TableCaption = React.forwardRef(({ className, ...props }, ref) => (
  <caption
    ref={ref}
    className={cn("mt-6 text-sm text-foreground-muted font-medium", className)}
    {...props}
  />
))
TableCaption.displayName = "TableCaption"

// Premium Data Table Component
const DataTable = ({ 
  data = [], 
  columns = [], 
  onRowClick,
  sortable = true,
  className,
  emptyMessage = "No data available"
}) => {
  const [sortConfig, setSortConfig] = React.useState({ key: null, direction: null });

  const handleSort = (key) => {
    if (!sortable) return;
    
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  const sortedData = React.useMemo(() => {
    if (!sortConfig.key) return data;
    
    return [...data].sort((a, b) => {
      const aVal = a[sortConfig.key];
      const bVal = b[sortConfig.key];
      
      if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
  }, [data, sortConfig]);

  return (
    <Table className={className} variant="premium">
      <TableHeader>
        <TableRow interactive={false}>
          {columns.map((column) => (
            <TableHead
              key={column.key}
              sortable={sortable && column.sortable !== false}
              sortDirection={sortConfig.key === column.key ? sortConfig.direction : null}
              onSort={() => handleSort(column.key)}
              className={column.headerClassName}
            >
              {column.header}
            </TableHead>
          ))}
        </TableRow>
      </TableHeader>
      <TableBody>
        {sortedData.length === 0 ? (
          <TableRow interactive={false}>
            <TableCell colSpan={columns.length} className="text-center py-12">
              <div className="text-foreground-muted">
                {emptyMessage}
              </div>
            </TableCell>
          </TableRow>
        ) : (
          sortedData.map((row, index) => (
            <TableRow
              key={row.id || index}
              className={cn(
                onRowClick && "cursor-pointer",
                "animate-fade-in"
              )}
              style={{ animationDelay: `${index * 0.05}s` }}
              onClick={() => onRowClick?.(row)}
            >
              {columns.map((column) => (
                <TableCell 
                  key={column.key} 
                  className={column.cellClassName}
                >
                  {column.render ? column.render(row[column.key], row) : row[column.key]}
                </TableCell>
              ))}
            </TableRow>
          ))
        )}
      </TableBody>
    </Table>
  );
};

// Status Badge Component for tables
const StatusBadge = ({ status, variant = "default" }) => {
  const variants = {
    success: "bg-accent-emerald/20 text-accent-emerald border-accent-emerald/30",
    warning: "bg-accent-gold/20 text-accent-gold border-accent-gold/30",
    error: "bg-destructive/20 text-destructive border-destructive/30",
    info: "bg-primary/20 text-primary border-primary/30",
    default: "bg-muted text-foreground-muted border-border"
  };

  return (
    <span className={cn(
      "inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border",
      variants[variant] || variants.default
    )}>
      {status}
    </span>
  );
};

export {
  Table,
  TableHeader,
  TableBody,
  TableFooter,
  TableHead,
  TableRow,
  TableCell,
  TableCaption,
  DataTable,
  StatusBadge,
  tableVariants,
}
