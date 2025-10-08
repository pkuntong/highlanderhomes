import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { CheckCircle, Clock, XCircle, Trash2, CheckSquare } from "lucide-react";
import { useState } from "react";
import { doc, updateDoc, deleteDoc } from "firebase/firestore";
import { db } from "@/firebase";
import { useToast } from "@/components/ui/use-toast";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

export default function BulkActions({ selectedProperties, onComplete, onClearSelection }) {
  const [updating, setUpdating] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const { toast } = useToast();

  if (selectedProperties.length === 0) return null;

  const handleBulkPaymentUpdate = async (status) => {
    setUpdating(true);
    try {
      await Promise.all(
        selectedProperties.map(property =>
          updateDoc(doc(db, "properties", property.id), {
            paymentStatus: status,
            lastPaymentUpdate: new Date().toISOString()
          })
        )
      );

      toast({
        title: "Bulk Update Complete",
        description: `${selectedProperties.length} properties marked as ${status}`,
      });

      onComplete();
      onClearSelection();
    } catch (error) {
      console.error("Error updating properties:", error);
      toast({
        title: "Error",
        description: "Failed to update some properties",
        variant: "destructive",
      });
    } finally {
      setUpdating(false);
    }
  };

  const handleBulkStatusUpdate = async (status) => {
    setUpdating(true);
    try {
      await Promise.all(
        selectedProperties.map(property =>
          updateDoc(doc(db, "properties", property.id), {
            status: status,
            lastUpdated: new Date().toISOString()
          })
        )
      );

      toast({
        title: "Bulk Update Complete",
        description: `${selectedProperties.length} properties marked as ${status}`,
      });

      onComplete();
      onClearSelection();
    } catch (error) {
      console.error("Error updating properties:", error);
      toast({
        title: "Error",
        description: "Failed to update some properties",
        variant: "destructive",
      });
    } finally {
      setUpdating(false);
    }
  };

  const handleBulkDelete = async () => {
    setUpdating(true);
    try {
      await Promise.all(
        selectedProperties.map(property =>
          deleteDoc(doc(db, "properties", property.id))
        )
      );

      toast({
        title: "Properties Deleted",
        description: `${selectedProperties.length} properties removed`,
      });

      onComplete();
      onClearSelection();
      setShowDeleteConfirm(false);
    } catch (error) {
      console.error("Error deleting properties:", error);
      toast({
        title: "Error",
        description: "Failed to delete some properties",
        variant: "destructive",
      });
    } finally {
      setUpdating(false);
    }
  };

  return (
    <>
      <div className="fixed bottom-6 left-1/2 transform -translate-x-1/2 z-50 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-2xl p-4">
        <div className="flex flex-col sm:flex-row items-center gap-4">
          <div className="flex items-center gap-2">
            <CheckSquare className="h-5 w-5 text-highlander-600" />
            <span className="font-semibold">
              {selectedProperties.length} selected
            </span>
          </div>

          <div className="flex flex-wrap gap-2">
            {/* Payment Status Actions */}
            <div className="flex gap-1 border-r pr-2">
              <Button
                size="sm"
                variant="outline"
                onClick={() => handleBulkPaymentUpdate('paid')}
                disabled={updating}
                className="text-green-600 hover:bg-green-50"
              >
                <CheckCircle className="h-4 w-4 mr-1" />
                Paid
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => handleBulkPaymentUpdate('pending')}
                disabled={updating}
                className="text-yellow-600 hover:bg-yellow-50"
              >
                <Clock className="h-4 w-4 mr-1" />
                Pending
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => handleBulkPaymentUpdate('overdue')}
                disabled={updating}
                className="text-red-600 hover:bg-red-50"
              >
                <XCircle className="h-4 w-4 mr-1" />
                Overdue
              </Button>
            </div>

            {/* Property Status Actions */}
            <div className="flex gap-1 border-r pr-2">
              <Button
                size="sm"
                variant="outline"
                onClick={() => handleBulkStatusUpdate('occupied')}
                disabled={updating}
              >
                Occupied
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => handleBulkStatusUpdate('vacant')}
                disabled={updating}
              >
                Vacant
              </Button>
            </div>

            {/* Delete Action */}
            <Button
              size="sm"
              variant="destructive"
              onClick={() => setShowDeleteConfirm(true)}
              disabled={updating}
            >
              <Trash2 className="h-4 w-4 mr-1" />
              Delete
            </Button>

            {/* Clear Selection */}
            <Button
              size="sm"
              variant="ghost"
              onClick={onClearSelection}
              disabled={updating}
            >
              Clear
            </Button>
          </div>
        </div>
      </div>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={showDeleteConfirm} onOpenChange={setShowDeleteConfirm}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete {selectedProperties.length} Properties?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the selected properties
              and all associated data.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleBulkDelete} className="bg-red-600 hover:bg-red-700">
              Delete Properties
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
