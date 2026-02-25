# Pragtech Construction Management Suite -- User Guide

## What This Is

Six Odoo 18 modules that together handle the full lifecycle of a construction business: acquiring land, planning projects, estimating costs, hiring contractors, tracking expenses, and managing tenders. Everything ties back to Odoo's core accounting, inventory, and project modules.

The modules:

| Module | Purpose |
|--------|---------|
| pragtech_ppc | Core project planning, WBS, budgeting, material/labour estimation |
| pragtech_ppc_ganttchart | Visual Gantt chart for project timelines |
| pragtech_contracting | Sub-contractor work orders, RA billing, retention |
| pragtech_tender_management | Publish tenders, collect bids, pick winners |
| odoo_pragtech_construction_land_acquisition | Property records, proposals, sales |
| odoo_pragtech_construction_project_expenses | Link employee expenses to projects |

---

## Module 1: Project Planning and Controlling (pragtech_ppc)

This is the backbone. Everything else plugs into it.

### Concepts

**Project** -- top-level record. Has a name, code, location, assigned team (architect, consultant, engineer). Creating a project auto-creates a stock location for tracking consumed materials.

**Sub-Project** -- optional grouping within a project (e.g., "Phase 1", "Building A"). Can have its own budget if `budget_applicable` is checked.

**WBS (Work Breakdown Structure)** -- a hierarchical tree of tasks under a project/sub-project. Four levels:

```
Project
  └── Sub-Project
        └── WBS Node (is_wbs=True)
              └── Task Group (is_group=True)
                    └── Task (is_task=True)
```

Each task has planned/actual start and finish dates, a completion percentage (0-100), and status (unplanned, non_started, started, in_complete, completed).

**Task Library** -- reusable templates. Define a library task once with its standard materials and labour, then apply it to actual tasks. The `min_qty` field scales all quantities proportionally.

**Materials and Labour** -- each task can have material lines (product, UOM, qty, rate) and labour lines (labour master, UOM, qty, rate). These feed cost estimates and requisitions.

**Category Budget** -- allocate budget per task category within a WBS. Split the budget between materials and labour by percentage. The system tracks estimated vs. actual spend.

**Stages and Approvals** -- projects, sub-projects, budgets, and requisitions move through stages (Draft, Approved, Foreclosed). Every transition is logged in an audit trail.

### How to Use It

1. Go to **Execution** menu
2. Create a Project (fill name, code, location, team)
3. Create Sub-Projects under the project if needed
4. Build your WBS: create WBS nodes, then groups, then tasks
5. For each task, add material and labour estimates (or use a Task Library)
6. Set planned dates on tasks
7. Create Category Budgets to control spending
8. As work progresses, update actual dates and completion percentages
9. Use the Task Scheduler wizard for bulk updates

### Menus

- Execution > Projects
- Execution > Sub-Projects
- Execution > Tasks (WBS tree)
- Execution > Task Libraries
- Execution > Category Budget
- Execution > Labour Requisitions
- Execution > Scheduler (bulk update wizard)
- Configuration > Task Categories, Labour Categories, Stage Master

### User Roles

| Role | Can Do |
|------|--------|
| Manager | Full access, create/delete everything |
| Asst. Manager | Create, read, write. No delete. |
| Sr. Executive | Read, write. No create or delete. |
| User | Read only |

---

## Module 2: Gantt Chart (pragtech_ppc_ganttchart)

Adds a visual Gantt chart view for project tasks. Opens as a client action (`gantt_chart`) that loads an interactive JavaScript-based timeline.

### How to Use It

1. Open the Gantt Chart from the menu (or via a wizard)
2. The chart loads all tasks with their planned dates
3. Use the toolbar to zoom in/out, undo/redo, print
4. Edit task dates, durations, and dependencies directly in the chart
5. Click Save to persist changes back to Odoo

### Features

- Drag tasks to reschedule
- Set dependencies between tasks
- Critical path highlighting
- Split view (data table + chart)
- Print support

---

## Module 3: Contracting (pragtech_contracting)

Manages the full sub-contracting cycle: requisitions, quotations, work orders, billing, and recoveries.

### Concepts

**Labour Requisition** -- request for a specific labour type and quantity, linked to a project/task.

**Labour Quotation** -- contractor's price quote for labour. Each line has a labour type, quantity, rate, taxes, and retention percentage.

**Quotation Comparison** -- compare up to 6 contractors side by side on the same labour items. Mark the approved contractor per item, and the system updates contractor pricing records.

**Work Order** -- the actual contract with a contractor. Created from approved requisitions. Each line has a payment schedule (milestones like "release 30% at 40% completion").

**Work Completion** -- record the percentage of work completed per line item.

**RA Bill (Running Account Bill)** -- incremental billing. Calculates payable amount based on completion, minus retention, plus/minus recoveries. Can generate an accounting invoice.

**Recoveries** -- track advances given to contractors, debit notes (penalties), and credit notes. Each RA bill can deduct recovery amounts.

**Retention Release** -- after work order completion, release the retained amounts to the contractor.

### Workflow

```
Labour Requisition (need labour)
  --> Labour Quotation (contractor quotes price)
    --> Quotation Comparison (pick best contractor)
      --> Work Order (contract signed)
        --> Work Completion (track progress)
          --> RA Bill (pay contractor incrementally)
            --> Advance/Debit/Credit Recovery (deductions)
              --> Retention Release (final settlement)
```

### How to Use It

1. Go to **Contracting** menu
2. Create a Labour Requisition (specify project, task, labour type, qty)
3. Get the requisition approved (Change Stage)
4. Collect quotations from contractors
5. Use Quotation Comparison to evaluate
6. Create a Work Order from approved requisitions
7. Define payment schedules per line (must total 100%)
8. Get the work order approved
9. Record work completion as work progresses
10. Create RA Bills for payment (system calculates amounts with retention and tax)
11. Process recoveries (advances, debit notes) against RA bills
12. Release retention after final completion

### Menus

- Contracting > Contractors
- Contracting > Labour Quotation
- Contracting > Quotation Comparison
- Contracting > Work Order
- Contracting > RA Bill
- Contracting > Advance Recovery, Debit Recovery, Credit Recovery
- Contracting > Retention Release

### Contractor Fields on Partners

The module extends `res.partner` with:
- `contractor` (boolean)
- `contractor_status`, `grading`, `credit_capacity`
- Tax numbers: `cst_no`, `vat_no`, `pan_no`, `wct_no`
- Registration numbers: `pf_code_registration_no`, `esic_no`
- `trial_allowed`, `trial_used` (trial period tracking)

---

## Module 4: Tender Management (pragtech_tender_management)

Publish tenders, collect bids from contractors via the website, and pick a winner.

### Concepts

**Tender** -- the RFP/NIT document. Contains materials, labour, and overhead line items with quantities. Has questionnaires for bidder eligibility. Publishes to the website.

**Enquiry** -- a bidder registers interest. System auto-populates the questionnaire. Bidder answers are scored.

**Estimation** -- internal cost estimate for a tender, linked to an approved enquiry.

**Bid** -- a contractor's price submission. Includes pricing for materials, labour, and overhead. System auto-ranks bids by total amount (lowest = rank 1). Marking a bid as "Won" marks all others as "Lost" and completes the tender.

### Workflow

```
Create Tender (Draft)
  --> Submit --> Approve (manager)
    --> Publish on Website
      --> Bidders view tender details
        --> Bidders submit bids with pricing
          --> Bids auto-ranked by total price
            --> Review bids, mark winner
              --> Tender Done
```

### How to Use It

1. Go to **Tenders** menu
2. Create a tender: fill in name, location, budget, dates, deposits
3. Add material, labour, and overhead line items with quantities and last known prices
4. Add questionnaire questions for bidder eligibility
5. Submit the tender, then get it approved
6. Publish to website (toggle "Published" checkbox)
7. Bidders visit `/tenders` on your website to view and submit bids
8. Review bids under **Bids** menu (auto-ranked by price)
9. Move bids to "Under Review"
10. Mark the winning bid as "Won"

### Menus

- Tenders > Tenders
- Tenders > Bids
- Tenders > Enquiry
- Tenders > Estimation
- Tenders > Contractors
- Configuration > Questionnaire, Department, Job Type

### Website Integration

Public URLs:
- `/tenders` -- list of published tenders
- `/tender/<id>` -- tender details and bid submission form

---

## Module 5: Land Acquisition (odoo_pragtech_construction_land_acquisition)

Track properties, manage ownership, create proposals, and generate sales orders.

### Concepts

**Land Acquisition** -- the property record. Has address, coordinates, photos, legal documents, ownership details, nearby landmarks, development phases, and pricing (lease and/or sale).

**Ownership** -- track co-owners with partnership percentages. System validates the total does not exceed 100%.

**Land Proposal** -- a customer-facing quote for leasing or buying a property. Auto-copies pricing from the property record. Can generate a sales order.

### Workflow

```
Create Property (Booking Open)
  --> Check Availability (must select lease or sale)
    --> Available
      --> Create Proposal for Customer
        --> Generate Sales Order
          --> Booked --> Sold
```

### How to Use It

1. Go to **Land Acquisition** menu
2. Create a property: name, address, coordinates, photos
3. Add owners with partnership percentages
4. Set pricing (lease cost, sale cost, rent type)
5. Upload legal documents and property photos
6. Click "Check Availability" to make it available
7. Create a Land Proposal for an interested customer
8. From the proposal, generate a sales order

### Menus

- Land Acquisition > Land Property
- Land Acquisition > Land Proposal
- Configuration > Location, Area, Property Type, Document Type, Place Type

---

## Module 6: Project Expenses (odoo_pragtech_construction_project_expenses)

Adds a `project_id` field to the standard HR Expense module. That is all it does, and that is all it needs to do.

### How to Use It

1. Go to **Expenses** menu (standard HR module)
2. Create an expense as usual
3. Select the **Project** field to link the expense to a construction project
4. Submit, approve, and post as normal
5. Use expense reports to analyze costs per project

---

## Use Case: Building a Residential Complex

Here is a complete walkthrough using sample data. The scenario: your company, Ovoco Construction, is building a 50-unit residential complex called "Sunrise Heights."

### Step 1: Set Up the Project (pragtech_ppc)

**Create the Project:**

| Field | Value |
|-------|-------|
| Name | Sunrise Heights |
| Code | SH-001 |
| City | Portland |
| Architect | Jane Mitchell |
| Engineer In Charge | Tom Rivera |
| Saleable Area | 45,000 sqft |
| Builtup Area | 52,000 sqft |

**Create Sub-Projects:**

| Sub-Project | Budget Applicable | Start Date | End Date |
|-------------|-------------------|------------|----------|
| Foundation Work | Yes | 2026-03-01 | 2026-06-30 |
| Superstructure | Yes | 2026-05-01 | 2026-12-31 |
| Finishing | Yes | 2026-10-01 | 2027-03-31 |

**Build the WBS for "Foundation Work":**

```
Foundation Work (Sub-Project)
  └── FDN-WBS (WBS Node)
        ├── Excavation (Group)
        │     ├── Site Clearing (Task)
        │     ├── Trench Excavation (Task)
        │     └── Backfilling (Task)
        ├── Concrete Work (Group)
        │     ├── PCC (Plain Cement Concrete) (Task)
        │     ├── RCC Footings (Task)
        │     └── Plinth Beam (Task)
        └── Waterproofing (Group)
              ├── Foundation Waterproofing (Task)
              └── Drainage Layer (Task)
```

**Add Material Estimates to "RCC Footings" task:**

| Material | UOM | Qty | Rate | Subtotal |
|----------|-----|-----|------|----------|
| OPC Cement 53 Grade | Bag | 450 | 380.00 | 171,000.00 |
| 20mm Aggregate | Ton | 85 | 1,200.00 | 102,000.00 |
| River Sand | Ton | 60 | 1,800.00 | 108,000.00 |
| TMT Steel 12mm | Ton | 18 | 52,000.00 | 936,000.00 |
| TMT Steel 16mm | Ton | 12 | 51,500.00 | 618,000.00 |

**Add Labour Estimates to "RCC Footings" task:**

| Labour | UOM | Qty | Rate | Subtotal |
|--------|-----|-----|------|----------|
| Mason | Day | 45 | 850.00 | 38,250.00 |
| Helper | Day | 90 | 450.00 | 40,500.00 |
| Bar Bender | Day | 30 | 900.00 | 27,000.00 |
| Carpenter (Formwork) | Day | 25 | 800.00 | 20,000.00 |

**Create Category Budget for Foundation Work:**

| Task Category | Qty | Rate | Amount | Material % | Labour % |
|---------------|-----|------|--------|-----------|----------|
| Excavation | 1 | 500,000 | 500,000 | 40 | 60 |
| Concrete Work | 1 | 2,500,000 | 2,500,000 | 70 | 30 |
| Waterproofing | 1 | 300,000 | 300,000 | 80 | 20 |

### Step 2: Acquire the Land (land_acquisition)

**Create Property Record:**

| Field | Value |
|-------|-------|
| Name | Sunrise Heights Plot |
| Location | Portland |
| Area | Hillside District |
| Property Type | Residential |
| Latitude | 45.5152 |
| Longitude | -122.6784 |
| Is Sale | Yes |
| Sale Cost | 2,500,000.00 |
| Unit Price | 48.08/sqft |

**Add Owners:**

| Owner | Partnership % |
|-------|--------------|
| Ovoco Holdings LLC | 60 |
| Pacific Development Corp | 40 |

**Add Nearby Landmarks:**

| Landmark | Distance (km) | Type |
|----------|---------------|------|
| Portland General Hospital | 2.5 | Hospital |
| Lincoln Elementary School | 1.2 | School |
| Hawthorne Market | 0.8 | Market |

### Step 3: Publish a Tender (tender_management)

**Create Tender for Foundation Concrete Work:**

| Field | Value |
|-------|-------|
| Tender Name | Sunrise Heights -- Foundation Concrete |
| Total Budget | 2,500,000.00 |
| Earnest Money Deposit | 50,000.00 |
| Performance Security | 125,000.00 |
| Bid From | 2026-03-01 |
| Bid To | 2026-03-21 |

**Add Tender Material Lines:**

| Product | Qty | UOM | Last Price |
|---------|-----|-----|------------|
| OPC Cement 53 Grade | 450 | Bag | 380.00 |
| 20mm Aggregate | 85 | Ton | 1,200.00 |
| River Sand | 60 | Ton | 1,800.00 |
| TMT Steel 12mm | 18 | Ton | 52,000.00 |
| TMT Steel 16mm | 12 | Ton | 51,500.00 |

**Add Questionnaire:**

| Question | Type |
|----------|------|
| Years of experience in RCC construction? | Numerical |
| Number of similar projects completed? | Numerical |
| Do you hold ISO 9001 certification? | Text |

**Submit, approve, and publish the tender.**

Three contractors submit bids through the website:

| Bidder | Material Total | Labour Total | Overhead Total | Grand Total | Auto Rank |
|--------|---------------|-------------|----------------|-------------|-----------|
| Pacific Concrete Inc. | 1,780,000 | 420,000 | 85,000 | 2,285,000 | 1 |
| Northwest Builders | 1,820,000 | 450,000 | 90,000 | 2,360,000 | 2 |
| Rose City Construction | 1,900,000 | 480,000 | 95,000 | 2,475,000 | 3 |

Mark Pacific Concrete Inc. as the winner.

### Step 4: Create the Contract (contracting)

**Create Labour Requisition:**

| Field | Value |
|-------|-------|
| Project | Sunrise Heights |
| WBS | FDN-WBS |
| Labour | Mason |
| Quantity | 45 days |

**Create Work Order for Pacific Concrete Inc.:**

| Field | Value |
|-------|-------|
| Contractor | Pacific Concrete Inc. |
| Project | Sunrise Heights |
| WBS | FDN-WBS |

**Work Order Lines:**

| Labour | Task | Qty | Rate | Amount |
|--------|------|-----|------|--------|
| Mason | RCC Footings | 45 | 850 | 38,250 |
| Helper | RCC Footings | 90 | 450 | 40,500 |
| Bar Bender | RCC Footings | 30 | 900 | 27,000 |
| Carpenter | RCC Footings | 25 | 800 | 20,000 |

**Payment Schedule for Mason line:**

| Milestone | Release % | At Completion % |
|-----------|-----------|-----------------|
| Mobilization | 10 | 0 |
| Foundation 50% | 40 | 50 |
| Foundation Complete | 50 | 100 |

**Approve the work order.**

### Step 5: Track Progress and Bill

**Record Work Completion (after 2 weeks):**

| Line | Completion % |
|------|-------------|
| Mason | 50 |
| Helper | 50 |
| Bar Bender | 45 |
| Carpenter | 40 |

**Create RA Bill #1:**

The system calculates amounts based on completion percentage, retention (typically 5-10%), and applicable taxes. Example for Mason line at 50% with 5% retention:

```
Gross: 45 days x 850 x 50% = 19,125.00
Retention: 19,125 x 5% = 956.25
Payable: 19,125 - 956.25 = 18,168.75
```

### Step 6: Track Expenses (project_expenses)

| Employee | Expense | Amount | Project |
|----------|---------|--------|---------|
| Tom Rivera | Site travel - March | 450.00 | Sunrise Heights |
| Tom Rivera | Safety equipment | 2,800.00 | Sunrise Heights |
| Jane Mitchell | Soil testing lab fees | 3,500.00 | Sunrise Heights |

### Step 7: Use the Gantt Chart

Open the Gantt Chart view to see all Foundation Work tasks laid out on a timeline. Drag tasks to adjust dates. Set dependencies (e.g., "RCC Footings" cannot start until "Trench Excavation" is complete). The chart highlights the critical path.

---

## Configuration Checklist

Before using the system, set up these master records:

1. **Stage Master** (pragtech_ppc) -- create Draft, Approved, Foreclosed stages
2. **Task Categories** -- e.g., Excavation, Concrete, Electrical, Plumbing
3. **Labour Categories** -- e.g., Skilled, Semi-Skilled, Unskilled
4. **Labour Masters** -- e.g., Mason, Carpenter, Electrician (with rates)
5. **Products** -- materials like cement, steel, sand (with UOM and rates)
6. **Questionnaire** (tender_management) -- standard technical questions
7. **Location/Area** (land_acquisition) -- geographic hierarchy
8. **Property Types, Document Types, Place Types** (land_acquisition)
9. **Payment Schedule Templates** (contracting) -- reusable milestone definitions
10. **User Groups** -- assign employees to the appropriate access level

---

## Tips

- Always build your WBS before estimating. The hierarchy drives budget tracking and reporting.
- Use Task Libraries to standardize estimates. Define a library task for "RCC Column per cum" once, then apply it with different `min_qty` values to scale quantities.
- Set up Category Budgets early. They enforce spending discipline and provide variance reporting.
- The Gantt Chart works best after all tasks have planned dates. Update it as actuals change.
- Payment schedules on work orders must total exactly 100%. The system will reject anything else.
- Tender questionnaire scores help shortlist bidders, but the final ranking is by price.
- Always approve requisitions before creating work orders. The work order pulls quantities from approved requisitions.
- RA Bills support incremental billing. You do not need to wait for 100% completion to issue a bill.
