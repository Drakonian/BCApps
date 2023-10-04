﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 456 "No. Series"
{
    AdditionalSearchTerms = 'numbering,number series';
    ApplicationArea = Basic, Suite;
    Caption = 'No. Series';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "No. Series";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number series code.';
                }
                field("No. Series Type"; Rec."No. Series Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series type that is associated with the number series code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the number series.';
                }
                field(StartDate; StartDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    Editable = false;
                    ToolTip = 'Specifies the date from which you want this number series to apply. You use this field if you want to start a new series at the beginning of a new period. You set up a number series line for each period. The program will automatically switch to the new series on the starting date.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
                    begin
                        StatelessNoSeriesManagement.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(StartNo; StartNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting No.';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the first number in the series.';

                    trigger OnDrillDown()
                    var
                        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
                    begin
                        StatelessNoSeriesManagement.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(EndNo; EndNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending No.';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the last number in the series.';

                    trigger OnDrillDown()
                    var
                        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
                    begin
                        StatelessNoSeriesManagement.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(LastDateUsed; LastDateUsed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Date Used';
                    Editable = false;
                    ToolTip = 'Specifies the date when a number was most recently assigned from the number series.';

                    trigger OnDrillDown()
                    var
                        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
                    begin
                        StatelessNoSeriesManagement.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(LastNoUsed; LastNoUsed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last No. Used';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the last number that was used from the number series.';

                    trigger OnDrillDown()
                    var
                        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
                    begin
                        StatelessNoSeriesManagement.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(WarningNo; WarningNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Warning No.';
                    Editable = false;
                    ToolTip = 'Specifies when you want to receive a warning that the number series is running out. You enter a number from the series. The program will provide a warning when this number is reached. You can enter a maximum of 20 characters, both numbers and letters.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
                    begin
                        StatelessNoSeriesManagement.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(IncrementByNo; IncrementByNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Increment-by No.';
                    Editable = false;
                    ToolTip = 'Specifies the value for incrementing the numeric part of the series.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
                    begin
                        StatelessNoSeriesManagement.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field("Default Nos."; Rec."Default Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this number series will be used to assign numbers automatically.';
                }
                field("Manual Nos."; Rec."Manual Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can enter numbers manually instead of using this number series.';
                }
                field("Date Order"; Rec."Date Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to check that numbers are assigned chronologically.';
                }
                field(AllowGapsCtrl; AllowGaps)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Allow Gaps in Nos.';
                    ToolTip = 'Specifies that a number assigned from the number series can later be deleted. This is practical for records, such as item cards and warehouse documents that, unlike financial transactions, can be deleted and cause gaps in the number sequence. This setting also means that new numbers will be generated and assigned in a faster, non-blocking way. NOTE: If an error occurs on a new record that will be assigned a number from such a number series when it is completed, the number in question will be lost, causing a gap in the sequence.';

                    trigger OnValidate()
                    var
                        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
                    begin
                        Rec.TestField(Code);
                        StatelessNoSeriesManagement.SetAllowGaps(Rec, AllowGaps);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

#pragma warning disable AA0219 // The Tooltip property for PageAction must start with 'Specifies'.
    actions
    {
        area(navigation)
        {
            group("&Series")
            {
                Caption = '&Series';
                Image = SerialNo;
                action(Lines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Lines';
                    Image = AllLines;
                    ToolTip = 'View or edit additional information about the number series lines.';

                    trigger OnAction()
                    var
                        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
                    begin
                        StatelessNoSeriesManagement.ShowNoSeriesLines(Rec);
                    end;
                }
                action(Relationships)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Relationships';
                    Image = Relationship;
                    RunObject = Page "No. Series Relationships";
                    RunPageLink = Code = field(Code);
                    ToolTip = 'View or edit relationships between number series.';
                }
            }
        }
        area(Processing)
        {
            action(TestNoSeriesSingle)
            {
                ApplicationArea = Basic, Suite;
                Image = TestFile;
                Caption = 'Test No. Series';
                ToolTip = 'Test whether the number series can generate new numbers.';

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"No. Series Check", Rec);
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Lines_Promoted; Lines)
                {
                }
                actionref(Relationships_Promoted; Relationships)
                {
                }
            }
        }
    }
#pragma warning restore AA0219

    trigger OnAfterGetRecord()
    var
        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
    begin
        StatelessNoSeriesManagement.UpdateLine(Rec, StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
    begin
        StatelessNoSeriesManagement.UpdateLine(Rec, StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps);
    end;

    var
        StartDate: Date;
        StartNo: Code[20];
        EndNo: Code[20];
        LastNoUsed: Code[20];
        WarningNo: Code[20];
        IncrementByNo: Integer;
        LastDateUsed: Date;
        AllowGaps: Boolean;

#if not CLEAN24
    [Obsolete('Use UpdateLine on codeunit NoSeriesManagement instead.', '24.0')]
    protected procedure UpdateLineActionOnPage()
    var
        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
    begin
        StatelessNoSeriesManagement.UpdateLine(Rec, StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps);
    end;
#endif
}
