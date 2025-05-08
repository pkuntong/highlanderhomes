import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import { Building, Home, Users, Calendar, Wrench, BarChart3, FileText } from "lucide-react";

const Index = () => {
  return (
    <div className="min-h-screen bg-gradient-to-b from-highlander-50 to-white">
      {/* Hero Section */}
      <section className="pt-20 pb-16 px-4 text-center">
        <div className="max-w-6xl mx-auto">
          <img 
            src="/HH Logo.png" 
            alt="Highlander Homes Logo" 
            className="w-24 h-24 mx-auto mb-6"
          />
          <h1 className="text-4xl md:text-5xl font-bold text-highlander-800 mb-4">
            Highlander Homes Property Management
          </h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto mb-8">
            Streamlined property management solutions for landlords and property managers.
          </p>
          <div className="flex flex-wrap justify-center gap-4">
            <Button asChild size="lg" className="bg-highlander-600 hover:bg-highlander-700">
              <Link to="/login">
                Login
              </Link>
            </Button>
            <Button asChild variant="outline" size="lg">
              <a href="mailto:highlanderhomes22@gmail.com">
                Contact Us
              </a>
            </Button>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-16 px-4 bg-white">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12">Powerful Property Management Tools</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <FeatureCard 
              icon={<Building className="h-10 w-10 text-highlander-500" />}
              title="Property Management"
              description="Easily manage all your properties in one place. Track occupancy, rent collection, and property details."
            />
            <FeatureCard 
              icon={<Users className="h-10 w-10 text-highlander-500" />}
              title="Tenant Management"
              description="Maintain tenant information, track lease agreements, and manage tenant communications efficiently."
            />
            <FeatureCard 
              icon={<Calendar className="h-10 w-10 text-highlander-500" />}
              title="Calendar & Reminders"
              description="Never miss important dates with our calendar and reminder system for rent collection, lease renewals, and more."
            />
            <FeatureCard 
              icon={<Wrench className="h-10 w-10 text-highlander-500" />}
              title="Maintenance Tracking"
              description="Keep track of maintenance requests, repairs, and property upkeep in an organized manner."
            />
            <FeatureCard 
              icon={<BarChart3 className="h-10 w-10 text-highlander-500" />}
              title="Analytics & Reports"
              description="Gain insights into your property portfolio with detailed analytics and customizable reports."
            />
            <FeatureCard 
              icon={<FileText className="h-10 w-10 text-highlander-500" />}
              title="Document Storage"
              description="Securely store and access important documents like leases, contracts, and inspection reports."
            />
          </div>
        </div>
      </section>

      {/* About Section */}
      <section className="py-16 px-4 bg-gray-50">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-3xl font-bold mb-6">About Highlander Homes</h2>
          <p className="text-lg text-gray-600 mb-8">
            Highlander Homes is dedicated to providing exceptional property management services. 
            Our platform is designed to streamline the property management process, giving landlords 
            and property managers the tools they need to efficiently manage their properties.
          </p>
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h3 className="text-xl font-semibold mb-4">Get in Touch</h3>
            <p className="mb-2"><strong>Phone:</strong> 240-449-4338</p>
            <p className="mb-2"><strong>Email:</strong> <a href="mailto:highlanderhomes22@gmail.com" className="text-highlander-600 hover:underline">highlanderhomes22@gmail.com</a></p>
            <p><strong>Highlander Homes LLC. 2025</strong></p>
          </div>
        </div>
      </section>
    </div>
  );
};

// Feature Card Component
const FeatureCard = ({ icon, title, description }) => (
  <div className="bg-white p-6 rounded-lg border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
    <div className="mb-4">{icon}</div>
    <h3 className="text-xl font-semibold mb-2">{title}</h3>
    <p className="text-gray-600">{description}</p>
  </div>
);

export default Index;