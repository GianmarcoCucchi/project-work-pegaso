digraph ER {
  graph [rankdir=LR, splines=ortho, nodesep=0.7, ranksep=1.0, bgcolor="white", pad="0.3"];
  node [shape=record, fontname="Arial", fontsize=10, style="rounded,filled", fillcolor="white", color="#333333"];
  edge [fontname="Arial", fontsize=9, color="#555555", arrowsize=0.8];

  organization [label="{organization|PK organization_id\llegal_name\ltax_code\lvat_number\lsubject_type\lacn_subject_code\lsector\lsubsector\lvalid_from / valid_to\lis_current\l}"];
  business_unit [label="{business_unit|PK business_unit_id\lFK organization_id\lname\ldescription\l}"];
  contact_person [label="{contact_person|PK contact_id\lFK organization_id\lfull_name\ljob_title\lemail\lphone\lis_external\l}"];
  supplier [label="{supplier|PK supplier_id\llegal_name\lvat_number\lcountry\lwebsite\lsupport_email\lsecurity_contact_email\l}"];
  asset [label="{asset|PK asset_id\lFK organization_id\lFK business_unit_id\lasset_code\lname\lasset_type\lenvironment\loverall_criticality\lcontains_personal_data\lvalid_from / valid_to\lis_current\l}"];
  service [label="{service|PK service_id\lFK organization_id\lFK business_unit_id\lservice_code\lname\lservice_category\lis_critical\lcriticality\lrto_minutes\lrpo_minutes\lvalid_from / valid_to\lis_current\l}"];
  service_asset [label="{service_asset|PK/FK service_id\lPK/FK asset_id\lrole_description\lis_mandatory\l}"];
  asset_relation [label="{asset_relation|PK asset_relation_id\lFK source_asset_id\lFK target_asset_id\lrelation_type\ldescription\l}"];
  responsibility_assignment [label="{responsibility_assignment|PK responsibility_id\lFK organization_id\lFK contact_id\lFK asset_id\lFK service_id\lrole\lvalid_from / valid_to\lis_current\l}"];
  supplier_dependency [label="{supplier_dependency|PK dependency_id\lFK organization_id\lFK supplier_id\lFK asset_id\lFK service_id\ldependency_type\lcontract_reference\lsla_description\lis_critical\lexit_strategy\l}"];
  audit_log [label="{audit_log|PK audit_id\ltable_name\lrecord_id\loperation\lchanged_at\lchanged_by\lold_data\lnew_data\l}"];

  organization -> business_unit [label="1:N"];
  organization -> contact_person [label="1:N"];
  organization -> asset [label="1:N"];
  organization -> service [label="1:N"];
  organization -> responsibility_assignment [label="1:N"];
  organization -> supplier_dependency [label="1:N"];

  business_unit -> asset [label="1:N"];
  business_unit -> service [label="1:N"];

  service -> service_asset [label="1:N"];
  asset -> service_asset [label="1:N"];

  asset -> asset_relation [label="source 1:N"];
  asset -> asset_relation [label="target 1:N"];

  contact_person -> responsibility_assignment [label="1:N"];
  asset -> responsibility_assignment [label="0:N"];
  service -> responsibility_assignment [label="0:N"];

  supplier -> supplier_dependency [label="1:N"];
  asset -> supplier_dependency [label="0:N"];
  service -> supplier_dependency [label="0:N"];

  organization -> audit_log [style=dashed, label="trigger audit"];
  asset -> audit_log [style=dashed, label="trigger audit"];
  service -> audit_log [style=dashed, label="trigger audit"];
  supplier -> audit_log [style=dashed, label="trigger audit"];
  contact_person -> audit_log [style=dashed, label="trigger audit"];
  responsibility_assignment -> audit_log [style=dashed, label="trigger audit"];
  supplier_dependency -> audit_log [style=dashed, label="trigger audit"];
}
