IntelliProcure – Smart Procurement and Inventory Optimization System
1. Project Overview
IntelliProcure is a smart procurement and inventory optimization system developed using SAP ABAP Cloud.

The objective is to reduce unnecessary external purchases by checking available internal resources and repair opportunities before recommending new purchases.

The system evaluates three alternatives:
- Internal resource reuse
- Repair of existing resources
- External procurement
It calculates the remaining procurement quantity, estimated cost, and potential savings.
2. Problem Statement
Organizations may purchase new resources even when reusable or repairable resources are already available internally. This can increase procurement expenses, reduce resource utilization, and create avoidable waste.

IntelliProcure follows a decision-support approach called Buy Only When Necessary.
3. Objectives
- Optimize procurement decisions.
- Improve internal resource utilization.
- Identify repair opportunities.
- Minimize unnecessary external purchases.
- Calculate estimated procurement costs and potential savings.
- Provide transparent procurement recommendations.
4. Technologies Used
Technology	Purpose
SAP BTP ABAP Environment	Cloud development platform
ABAP	Business logic
ABAP CDS Views	Data modeling
RAP (RESTful ABAP Programming Model)	Business object behavior
OData V4	API exposure
SAP Fiori Elements	User interface
Eclipse ADT	Development environment


5. System Architecture
1. Database Layer: Stores purchase requests, internal resources, repair candidates, and procurement decisions.
2. CDS View Layer: Provides structured access to application data.
3. RAP Behavior Layer: Implements the procurement simulation action.
4. Service Layer: Exposes application functionality through OData V4.
5. Presentation Layer: Provides the user interface through SAP Fiori Elements.
6. Main Modules
Purchase Request Management
Stores requester, department, resource, quantity, priority, and required date.
Internal Resource Management
Maintains available resources and their quantities.
Repair Management
Maintains repair candidates, repair status, estimated cost, and repair duration.
Procurement Decision Engine
Evaluates available internal resources and repair candidates before calculating the remaining purchase quantity.
Cost and Savings Analysis
Displays estimated procurement costs and potential savings.
7. Procurement Decision Workflow
1. User creates a purchase request.
2. System checks available internal resources.
3. System calculates the quantity that can be reused.
4. System checks eligible repair candidates.
5. System calculates the remaining quantity.
6. The remaining quantity is considered for external procurement.
7. System generates a procurement decision.
8. Estimated cost and savings are recorded.
Decision logic:

Requested Quantity = Internal Reuse + Repair Quantity + External Purchase Quantity
8. Database Tables
- ZINT_REQUEST – Purchase request information.
- ZINT_RESOURCE – Internal resource information.
- ZINT_REPAIR – Repair candidate information.
- ZINT_DECISION – Procurement decision and cost analysis.
9. CDS Views
- ZI_REQ – Purchase request CDS view.
- ZI_RESOURCE – Internal resource CDS view.
- ZI_REPAIR – Repair candidate CDS view.
- ZI_DECISION – Procurement decision CDS view.
10. RAP and OData Implementation
The application uses the RESTful ABAP Programming Model (RAP).

A custom action named simulate_alternatives is implemented in the purchase request behavior. The OData V4 service exposes the purchase request and procurement decision entities.

The simulation action endpoint is:

POST /PurchaseRequests/{request_id}/SAP__self.simulate_alternatives
ABAP Source Code
The core RAP behavior implementation is available in the ABAP_Source folder.

Main implementation: [`ZBP_I_REQ_Implementation.abap`](ABAP_Source/ZBP_I_REQ_Implementation.abap)

This implementation includes:
- Purchase request processing.
- Internal inventory availability checks.
- Repair candidate identification.
- External procurement quantity calculation.
- Estimated cost and savings calculation.
- Procurement decision generation.
- Purchase request status updates.
11. Sample Test Results
Parameter	Request 1	Request 2
Requested Quantity	20	5
Internal Reuse	12	5
Repair Quantity	1	0
Purchase Quantity	7	0
Estimated Cost	7150	0
Estimated Savings	12850	1250
Status	SIMULATED	SIMULATED


Total estimated savings in the sample test: 14,100 cost units.

The GET /ProcurementDecisions API was tested successfully and returned HTTP 200 with two decision records.

Note: Cost figures are sample application test values.
12. Key Features
- Smart procurement decision support.
- Internal resource reuse.
- Repair-based resource recovery.
- External purchase quantity calculation.
- Estimated cost and savings analysis.
- RAP-based business action.
- OData V4 service integration.
- SAP Fiori Elements interface.
13. Future Enhancements
- Integration with SAP S/4HANA procurement processes.
- Advanced inventory forecasting.
- AI-based demand prediction.
- Automated supplier selection.
- Real-time inventory synchronization.
- Interactive procurement analytics dashboard.
14. Conclusion
IntelliProcure demonstrates how SAP ABAP Cloud, CDS Views, RAP, OData V4, and SAP Fiori Elements can be combined to develop a procurement decision-support application.

The project follows a reuse-first and repair-first approach to help organizations reduce unnecessary purchases, improve resource utilization, and make cost-conscious procurement decisions.
Project: IntelliProcure – Smart Procurement and Inventory Optimization System

Platform: SAP BTP ABAP Environment

Development Environment: Eclipse IDE with ABAP Development Tools

GitHub Repository: https://github.com/Vinnu13-01-05/IntelliProcure

Project Website: https://vinnu13-01-05.github.io/IntelliProcure/
