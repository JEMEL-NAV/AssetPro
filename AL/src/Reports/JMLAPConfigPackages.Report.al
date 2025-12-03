report 70182300 "JML AP Config Packages"
{
    Caption = 'Import Configuration Packages';
    UsageCategory = Tasks;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                TempBuf: Record "Name/Value Buffer" temporary;
                ConfigXMLExchange: Codeunit "Config. XML Exchange";
                TempBlob: Codeunit "Temp Blob";
                TempBlobUncompressed: Codeunit "Temp Blob";
                InStream: InStream;
                OutStream: OutStream;
                Name1Txt: label 'PackageJML.AP.W1.EVAL.rapidstart', Locked = true;
                Value1Txt: label 'Evaluation - Sample Data. Install over Contonso demo data.';
            begin
                TempBuf.Init();
                TempBuf.ID := 1;
                TempBuf.Name := Name1Txt;
                TempBuf."Value" := Value1Txt;
                TempBuf.Insert(true);

                // TempBuf.Init();
                // TempBuf.ID := 2;
                // TempBuf.Name := Name2Txt;
                // TempBuf."Value" := Value2Txt;
                // TempBuf.Insert(true);

                if page.RunModal(page::"JML AP Config Packages", TempBuf) in [Action::Ok, Action::LookupOk] then begin
                    NavApp.GetResource(TempBuf.Name, InStream);
                    TempBlob.CreateOutStream(OutStream);
                    CopyStream(OutStream, InStream);
                    ConfigXMLExchange.DecompressPackageToBlob(TempBlob, TempBlobUncompressed);
                    TempBlobUncompressed.CreateInStream(InStream);
                    ConfigXMLExchange.ImportPackageXMLFromStream(InStream);

                    Page.run(page::"Config. Packages");
                end;
            end;

        }
    }
}