# -*- coding: utf-8 -*-
{
    'name': 'Odoo Construction Expense Management',
    'version': '18.0.1.0.0',
    'author': 'Pragmatic TechSoft Pvt Ltd.',
    "website": "http://www.pragtech.co.in",
    'category': 'Expense',
    'summary': 'Track project and non-project expenses for construction projects at project and company level.',
    'description': """  
Pragtech hr Expense    
====================
<keywords>
construction
construction management
construction app
construction module
project expenses
project 
expenses
odoo construction
construction project  
odoo expenses
expenses management
     """,
    'depends': ['hr_expense', 'project'],
    'data': [
        'views/hr_expense_view.xml'
    ],
    'images': ['static/description/animated-construction-expense-management.gif'],
    'live_test_url': 'https://www.pragtech.co.in/company/proposal-form.html?id=310&name=support-odoo-construction-expense',
    'license': 'OPL-1',
    'price': 292.4,
    'currency': 'USD',
    'auto_install': False,
    'installable': True,
}
