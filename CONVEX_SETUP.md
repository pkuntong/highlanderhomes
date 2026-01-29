# Convex Backend Setup Guide

This guide will help you set up Convex as the backend for your HighlanderHomes project.

## Prerequisites

- Node.js installed (v18 or higher)
- A Convex account (you mentioned you already have one)
- npm or yarn package manager

## Step 1: Install Convex

Run the following command in your project root:

```bash
npm install convex
```

## Step 2: Initialize Convex

If you haven't already initialized Convex in this project, run:

```bash
npx convex dev
```

This will:
- Create a `.env.local` file with your Convex deployment URL
- Start the Convex development server
- Watch for changes in your `convex/` folder

**Important:** When you run `npx convex dev`, you'll see output like:
```
Convex deployment URL: https://your-deployment-name.convex.cloud
```

Copy this URL - you'll need it for the iOS app configuration.

## Step 3: Update iOS Configuration

Once you have your Convex deployment URL, update the iOS app configuration:

1. Open `/Users/gnotnuk/Documents/highlanderhomes/HighlanderHomes/HighlanderHomes-iOS/Services/Convex/ConvexConfig.swift`

2. Replace the placeholder URL:
```swift
static let deploymentURL = "https://YOUR_DEPLOYMENT.convex.cloud"
```

With your actual deployment URL:
```swift
static let deploymentURL = "https://your-actual-deployment-name.convex.cloud"
```

## Step 4: Verify Schema Deployment

The schema and functions have been created in the `convex/` folder:

- `convex/schema.ts` - Database schema with all tables
- `convex/auth.ts` - Authentication functions
- `convex/properties.ts` - Property CRUD operations
- `convex/tenants.ts` - Tenant CRUD operations
- `convex/maintenanceRequests.ts` - Maintenance request operations
- `convex/contractors.ts` - Contractor operations
- `convex/feedEvents.ts` - Activity feed queries
- `convex/users.ts` - User profile operations

When you run `npx convex dev`, these will automatically be deployed to your Convex backend.

## Step 5: Test the Setup

### Test from Terminal

You can test your Convex functions using the Convex dashboard or via HTTP:

1. Go to your Convex dashboard: https://dashboard.convex.dev
2. Navigate to your deployment
3. Use the "Functions" tab to test queries and mutations

### Test from iOS App

The iOS app is already configured to use Convex. Once you:
1. Update the `ConvexConfig.swift` with your deployment URL
2. Ensure the app has network access
3. Implement proper authentication (see Authentication section below)

The app should be able to connect to your Convex backend.

## Authentication Setup

**Important:** The current authentication implementation is simplified for development. For production, you should:

1. **Use Convex Auth** - Convex provides built-in authentication:
   ```bash
   npm install @convex-dev/auth
   ```

2. **Or use a third-party auth provider** like Clerk, Auth0, or Firebase Auth

3. **Update the auth functions** in `convex/auth.ts` to use proper password hashing and JWT tokens

## Data Models

The following tables are defined in the schema:

- **users** - User accounts
- **properties** - Real estate properties
- **tenants** - Tenant information
- **maintenanceRequests** - Maintenance/repair requests
- **contractors** - Contractor/vendor information
- **rentPayments** - Rent payment records
- **expenses** - Property expenses
- **feedEvents** - Activity feed events

## Function Naming Convention

Functions follow this pattern:
- Queries: `{module}:list`, `{module}:get`
- Mutations: `{module}:create`, `{module}:update`, `{module}:delete`
- Actions: `auth:signUp`, `auth:signIn`, etc.

## Next Steps

1. **Deploy to Production**: When ready, run `npx convex deploy --prod`
2. **Set up Authentication**: Implement proper auth (see Authentication Setup above)
3. **Add Environment Variables**: Store sensitive config in Convex dashboard
4. **Set up Webhooks**: If you need to integrate with external services
5. **Monitor**: Use Convex dashboard to monitor usage and errors

## Troubleshooting

### "Convex deployment URL not found"
- Make sure you've run `npx convex dev` at least once
- Check `.env.local` file exists and contains `CONVEX_URL`

### "Function not found" errors
- Ensure `npx convex dev` is running
- Check that function names match between iOS app and Convex functions
- Verify the function is exported correctly in the `.ts` file

### Authentication errors
- Verify the auth token format matches what Convex expects
- Check that user exists in the `users` table
- Ensure userId is being passed correctly in function calls

## Resources

- [Convex Documentation](https://docs.convex.dev)
- [Convex Dashboard](https://dashboard.convex.dev)
- [Convex TypeScript Reference](https://docs.convex.dev/api)

## Support

If you encounter issues:
1. Check the Convex dashboard logs
2. Review the function code in `convex/` folder
3. Verify your deployment URL is correct
4. Ensure all dependencies are installed
