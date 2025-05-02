
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { FileText, Plus } from "lucide-react";

const Documents = () => {
  // Mock documents data
  const documents = [
    { id: 1, name: "Property Insurance - 123 Highland Ave", type: "PDF", date: "2025-03-15" },
    { id: 2, name: "Lease Agreement - 101 Bluegrass Ln", type: "DOCX", date: "2025-01-10" },
    { id: 3, name: "Inspection Report - 456 Bourbon St", type: "PDF", date: "2024-12-05" },
    { id: 4, name: "Maintenance Contract - HVAC Systems", type: "PDF", date: "2024-10-20" },
  ];

  return (
    <PageLayout title="Documents">
      <div className="mb-6 flex justify-between items-center">
        <h2 className="text-lg font-semibold">Property Documents</h2>
        <Button>
          <Plus className="mr-2 h-4 w-4" /> Upload Document
        </Button>
      </div>

      {documents.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {documents.map((document) => (
            <Card key={document.id} className="hover:bg-gray-50">
              <CardContent className="p-4 flex items-center">
                <div className="p-3 bg-highlander-100 rounded-lg mr-3">
                  <FileText className="h-6 w-6 text-highlander-700" />
                </div>
                <div className="flex-1">
                  <h3 className="font-medium text-sm">{document.name}</h3>
                  <div className="flex justify-between mt-1">
                    <span className="text-xs text-gray-500">{document.type}</span>
                    <span className="text-xs text-gray-500">
                      {new Date(document.date).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <FileText className="h-10 w-10 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-medium mb-2">No documents yet</h3>
            <p className="text-gray-500 mb-4">
              Upload property-related documents to keep everything in one place
            </p>
            <Button>
              <Plus className="mr-2 h-4 w-4" /> Upload Document
            </Button>
          </CardContent>
        </Card>
      )}
    </PageLayout>
  );
};

export default Documents;
