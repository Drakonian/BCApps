// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149034 "AIT Test Method Lines"
{
    Caption = 'Tests';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "AIT Test Method Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    Extensible = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("LoadTestCode"; Rec."Test Suite Code")
                {
                    Visible = false;
                }
                field(LineNo; Rec."Line No.")
                {
                    Visible = false;
                }
                field(CodeunitID; Rec."Codeunit ID")
                {
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(CodeunitName; Rec."Codeunit Name")
                {
                }
                field(InputDataset; Rec."Input Dataset")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Evaluation Setup"; EvaluationSetupTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Evaluators';
                    ToolTip = 'Specifies whether the evaluation is setup.';
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        AITEvaluator: Record "AIT Evaluator";
                        AITEvaluatorPage: Page "AIT Evaluators";
                    begin
                        AITEvaluator.SetRange("Test Suite Code", Rec."Test Suite Code");
                        AITEvaluator.SetRange("Test Method Line", Rec."Line No.");
                        AITEvaluatorPage.SetTableView(AITEvaluator);
                        AITEvaluatorPage.SetTestMethodLine(Rec."Line No.");
                        AITEvaluatorPage.Run();
                    end;
                }
                field(Status; Rec.Status)
                {
                }
                field("No. of Tests Executed"; Rec."No. of Tests Executed")
                {
                }
                field("No. of Tests Passed"; Rec."No. of Tests Passed")
                {
                    Style = Favorable;
                }
                field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                {
                    Editable = false;
                    Caption = 'No. of Tests Failed';
                    ToolTip = 'Specifies the number of failed tests for the test line.';
                    Style = Unfavorable;

                    trigger OnDrillDown()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                        AITLogEntry: Codeunit "AIT Log Entry";
                    begin
                        AITTestSuite.SetLoadFields(Version);
                        AITTestSuite.Get(Rec."Test Suite Code");
                        AITLogEntry.DrillDownFailedAITLogEntries(Rec."Test Suite Code", Rec."Line No.", AITTestSuite.Version);
                    end;
                }
                field(Accuracy; Rec."Test Method Line Accuracy")
                {
                }
                field(TurnsText; TurnsText)
                {
                    Visible = false;
                    Editable = false;
                    Caption = 'No. of Turns Passed';
                    ToolTip = 'Specifies the number of turns that passed out of the total number of turns.';

                    trigger OnDrillDown()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                        AITLogEntry: Codeunit "AIT Log Entry";
                    begin
                        AITTestSuite.SetLoadFields("Base Version");
                        AITTestSuite.Get(Rec."Test Suite Code");
                        AITLogEntry.DrillDownFailedAITLogEntries(Rec."Test Suite Code", Rec."Line No.", AITTestSuite."Base Version");
                    end;
                }
                field("No. of Turns"; Rec."No. of Turns")
                {
                    Visible = false;
                }
                field("No. of Turns Passed"; Rec."No. of Turns Passed")
                {
                    Visible = false;
                }
                field("No. of Turns Failed"; Rec."No. of Turns" - Rec."No. of Turns Passed")
                {
                    Visible = false;
                    Editable = false;
                    Caption = 'No. of Turns Failed';
                    ToolTip = 'Specifies the number of failed turns of the test line.';
                    Style = Unfavorable;

                    trigger OnDrillDown()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                        AITLogEntry: Codeunit "AIT Log Entry";
                    begin
                        AITTestSuite.SetLoadFields("Base Version");
                        AITTestSuite.Get(Rec."Test Suite Code");
                        AITLogEntry.DrillDownFailedAITLogEntries(Rec."Test Suite Code", Rec."Line No.", AITTestSuite."Base Version");
                    end;
                }
                field("No. of Operations"; Rec."No. of Operations")
                {
                    Visible = false;
                    Enabled = false;
                }
                field(Duration; Rec."Total Duration (ms)")
                {
                }
                field("Tokens Consumed"; Rec."Tokens Consumed")
                {
                }
                field(AvgDuration; AITTestSuiteMgt.GetAvgDuration(Rec))
                {
                    Caption = 'Average Duration (ms)';
                    ToolTip = 'Specifies average time taken to execute the test line.';
                    Visible = false;
                }
                field("No. of Tests Executed - Base"; Rec."No. of Tests Executed - Base")
                {
                    Visible = false;
                }
                field("No. of Tests Passed - Base"; Rec."No. of Tests Passed - Base")
                {
                    Style = Favorable;
                    Visible = false;
                }
                field("No. of Tests Failed - Base"; Rec."No. of Tests Executed - Base" - Rec."No. of Tests Passed - Base")
                {
                    Editable = false;
                    Caption = 'No. of Tests Failed - Base';
                    ToolTip = 'Specifies the number of failed tests for the base version of the test line.';
                    Style = Unfavorable;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                        AITLogEntry: Codeunit "AIT Log Entry";
                    begin
                        AITTestSuite.SetLoadFields("Base Version");
                        AITTestSuite.Get(Rec."Test Suite Code");
                        AITLogEntry.DrillDownFailedAITLogEntries(Rec."Test Suite Code", Rec."Line No.", AITTestSuite."Base Version");
                    end;
                }
                field("No. of Operations - Base"; Rec."No. of Operations - Base")
                {
                    Visible = false;
                    Enabled = false;
                }
                field(DurationBase; Rec."Total Duration - Base (ms)")
                {
                    Visible = false;
                }
                field(AvgDurationBase; GetAvg(Rec."No. of Tests Executed - Base", Rec."Total Duration - Base (ms)"))
                {
                    Caption = 'Average Duration Base (ms)';
                    ToolTip = 'Specifies average time taken to execute the base version of the test line.';
                    Visible = false;
                }
                field(AvgDurationDeltaPct; GetDiffPct(GetAvg(Rec."No. of Tests Executed - Base", Rec."Total Duration - Base (ms)"), GetAvg(Rec."No. of Tests Executed", Rec."Total Duration (ms)")))
                {
                    Caption = 'Change in Duration (%)';
                    ToolTip = 'Specifies difference in average test execution time compared to the base version.';
                    Visible = false;
                    AutoFormatType = 0;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Run Test")
            {
                Caption = 'Run Test';
                Image = Start;
                ToolTip = 'Starts running the AI Test Line.';

                trigger OnAction()
                begin
                    if Rec."Codeunit ID" = 0 then
                        exit;
                    AITTestSuiteMgt.RunAITestLine(Rec, false);
                    CurrPage.Update(false);
                end;
            }
            action(LogEntries)
            {
                Caption = 'Log Entries';
                Image = Entries;
                ToolTip = 'Open log entries for the line.';
                RunObject = page "AIT Log Entries";
                RunPageLink = "Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter");
            }
            action(Compare)
            {
                Caption = 'View Runs';
                Image = History;
                ToolTip = 'View the run history of the suite, for the selected line.';
                Scope = Repeater;

                trigger OnAction()
                var
                    AITTestMethodLine: Record "AIT Test Method Line";
                    AITRunHistory: Page "AIT Run History";
                begin
                    CurrPage.SetSelectionFilter(AITTestMethodLine);

                    if not AITTestMethodLine.FindFirst() then
                        Error(NoLineSelectedErr);

                    AITRunHistory.SetTestSuite(AITTestMethodLine."Test Suite Code");
                    AITRunHistory.FilterToLine(AITTestMethodLine."Line No.");
                    AITRunHistory.Run();
                end;
            }
        }
    }

    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        NoLineSelectedErr: Label 'Select a line to compare';
        TurnsText: Text;
        EvaluationSetupTxt: Text;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec."Test Suite Code" = '' then
            exit(true);
        if Rec."Test Suite Code" <> AITTestSuite.Code then
            if AITTestSuite.Get(Rec."Test Suite Code") then;
    end;

    trigger OnAfterGetRecord()
    begin
        EvaluationSetupTxt := AITTestSuiteMgt.GetEvaluationSetupText(CopyStr(Rec."Test Suite Code", 1, 10), Rec."Line No.");
        TurnsText := AITTestSuiteMgt.GetTurnsAsText(Rec);
    end;

    local procedure GetAvg(NumIterations: Integer; TotalNo: Integer): Integer
    begin
        if NumIterations = 0 then
            exit(0);
        exit(TotalNo div NumIterations);
    end;

    local procedure GetDiffPct(BaseNo: Integer; No: Integer): Decimal
    begin
        if BaseNo = 0 then
            exit(0);
        exit(Round((100 * (No - BaseNo)) / BaseNo, 0.1));
    end;

    internal procedure Refresh()
    begin
        CurrPage.Update(false);
        if Rec.Find() then;
    end;
}