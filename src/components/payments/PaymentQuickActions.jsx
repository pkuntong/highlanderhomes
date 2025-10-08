import { Button } from "@/components/ui/button";
import { CheckCircle, Clock, XCircle, DollarSign } from "lucide-react";
import { useState } from "react";
import { doc, updateDoc } from "firebase/firestore";
import { db } from "@/firebase";
import { useToast } from "@/components/ui/use-toast";

export default function PaymentQuickActions({ property, onUpdate }) {
  const [updating, setUpdating] = useState(false);
  const { toast } = useToast();

  const handleStatusUpdate = async (newStatus) => {
    if (!property?.id) return;

    setUpdating(true);
    try {
      const propertyRef = doc(db, "properties", property.id);
      await updateDoc(propertyRef, {
        paymentStatus: newStatus,
        lastPaymentUpdate: new Date().toISOString(),
      });

      toast({
        title: "Payment Status Updated",
        description: `Property marked as ${newStatus}`,
      });

      // Call the parent component's onUpdate if provided
      if (onUpdate) {
        await onUpdate();
      }
    } catch (error) {
      console.error("Error updating payment status:", error);
      toast({
        title: "Error",
        description: "Failed to update payment status",
        variant: "destructive",
      });
    } finally {
      setUpdating(false);
    }
  };

  const currentStatus = property?.paymentStatus || 'pending';

  return (
    <div className="flex flex-wrap gap-2">
      <Button
        size="sm"
        variant={currentStatus === 'paid' ? 'default' : 'outline'}
        onClick={() => handleStatusUpdate('paid')}
        disabled={updating || currentStatus === 'paid'}
        className={currentStatus === 'paid' ? 'bg-green-600 hover:bg-green-700' : ''}
      >
        <CheckCircle className="h-4 w-4 mr-1" />
        {currentStatus === 'paid' ? 'Paid' : 'Mark Paid'}
      </Button>

      <Button
        size="sm"
        variant={currentStatus === 'pending' ? 'default' : 'outline'}
        onClick={() => handleStatusUpdate('pending')}
        disabled={updating || currentStatus === 'pending'}
        className={currentStatus === 'pending' ? 'bg-yellow-600 hover:bg-yellow-700' : ''}
      >
        <Clock className="h-4 w-4 mr-1" />
        {currentStatus === 'pending' ? 'Pending' : 'Mark Pending'}
      </Button>

      <Button
        size="sm"
        variant={currentStatus === 'overdue' ? 'destructive' : 'outline'}
        onClick={() => handleStatusUpdate('overdue')}
        disabled={updating || currentStatus === 'overdue'}
      >
        <XCircle className="h-4 w-4 mr-1" />
        {currentStatus === 'overdue' ? 'Overdue' : 'Mark Overdue'}
      </Button>
    </div>
  );
}
