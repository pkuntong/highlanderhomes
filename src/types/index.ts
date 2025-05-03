export type Property = {
  id: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  yearBuilt: number | '';
  squareFootage: number | '';
  bedrooms: number | '';
  fullBathrooms: number | '';
  halfBathrooms: number | '';
  leaseType: string;
  monthlyRent: number | '';
  status: 'occupied' | 'vacant' | 'maintenance';
  paymentStatus?: 'paid' | 'pending' | 'overdue';
  description: string;
  imageUrl: string;
  imageBase64?: string;
};

export type Tenant = {
  id: string;
  name: string;
  email: string;
  phone: string;
  leaseStartDate: string;
  leaseEndDate: string;
  notes: string;
  propertyId?: string;
  rentAmount?: number;
  paymentStatus?: 'paid' | 'pending' | 'overdue';
};

export type MaintenanceLog = {
  id: string;
  propertyId: string;
  title: string;
  description: string;
  date: string;
  cost: number;
  status: 'pending' | 'in-progress' | 'completed';
  category: 'plumbing' | 'electrical' | 'hvac' | 'structural' | 'appliance' | 'other';
};

export type Insurance = {
  id: string;
  propertyId: string;
  company: string;
  policyNumber: string;
  startDate: string;
  expirationDate: string;
  premium: number;
  coverageAmount: number;
  type: 'property' | 'liability' | 'flood' | 'other';
  documents: string[];
};

export type License = {
  id: string;
  propertyId: string;
  type: string;
  number: string;
  issuanceDate: string;
  expirationDate: string;
  status: 'active' | 'pending' | 'expired';
  notes: string;
};

export type Reminder = {
  id: string;
  propertyId: string | null;
  tenantId: string | null;
  title: string;
  description: string;
  date: string;
  category: 'rent' | 'insurance' | 'license' | 'lease' | 'maintenance' | 'other';
  status: 'pending' | 'completed' | 'dismissed';
};
