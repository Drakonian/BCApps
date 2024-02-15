// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Environment.Configuration;
using System.Globalization;
using System.Azure.Identity;
using System.Utilities;
using System.Environment;
using System.Azure.KeyVault;
using System.RestClient;

/// <summary>
/// Library for managing AppSource product retrival and usage.
/// </summary>
codeunit 2515 "AppSource Product Manager" implements "AppSource Product Manager Dependencies"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AppSourceJsonUtilities: Codeunit "AppSource Json Utilities";
        Dependencies: Interface "AppSource Product Manager Dependencies";
        IsDependenciesSet: boolean;
        CatalogProductsUriLbl: label 'https://catalogapi.azure.com/products', Locked = true;
        CatalogApiVersionQueryParamNameLbl: label 'api-version', Locked = true;
        CatalogApiVersionQueryParamValueLbl: label '2023-05-01-preview', Locked = true;
        CatalogApiOrderByQueryParamNameLbl: label '$orderby', Locked = true;
        CatalogMarketQueryParamNameLbl: label 'market', Locked = true;
        CatalogLanguageQueryParamNameLbl: label 'language', Locked = true;
        CatalogApiFilterQueryParamNameLbl: Label '$filter', Locked = true;
        CatalogApiSelectQueryParamNameLbl: Label '$select', Locked = true;
        AppSourceListingUriLbl: Label 'https://appsource.microsoft.com/%1/product/dynamics-365-business-central/%2', Comment = '%1=Language ID, such as en-US, %2=Url Query Content', Locked = true;
        AppSourceUriLbl: Label 'https://appsource.microsoft.com/%1/marketplace/apps?product=dynamics-365-business-central', Comment = '1%=Language ID, such as en-US', Locked = true;
        NotSupportedOnPremisesErrorLbl: Label 'Not supported on premises.';
        UnsupportedLanguageNotificationLbl: Label 'Language %1 is not supported by AppSource. Defaulting to "en". Change the language in the user profile to use another language.', Comment = '%1=Language ID, such as en';
        UnsupportedMarketNotificationLbl: Label 'Market %1 is not supported by AppSource. Defaulting to "us". Change the region in the user profile to use another market.', Comment = '%1=Market ID, such as "us"';

    #region Dependency Interface implementation
    procedure GetCountryLetterCode(): Text[2]
    var
        entraTenant: Codeunit "Azure AD Tenant";
    begin
        exit(entraTenant.GetCountryLetterCode());
    end;

    procedure GetPreferredLanguage(): Text
    var
        entraTenant: Codeunit "Azure AD Tenant";
    begin
        exit(entraTenant.GetPreferredLanguage());
    end;

    procedure GetAadTenantID(): Text
    var
        entraTenant: Codeunit "Azure AD Tenant";
    begin
        exit(entraTenant.GetAadTenantID());
    end;

    procedure GetAzureKeyVaultSecret(SecretName: Text; var Secret: SecretText);
    var
        KeyVault: Codeunit "Azure Key Vault";
    begin
        KeyVault.GetAzureKeyVaultSecret(SecretName, Secret);
    end;

    procedure GetApplicationFamily(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetApplicationFamily());
    end;

    procedure IsSaas(): boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSaas());
    end;

    procedure GetFormatRegionOrDefault(FormatRegion: Text[80]): Text
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetFormatRegionOrDefault(FormatRegion));
    end;

    procedure GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken
    begin
        exit(RestClient.GetAsJSon(RequestUri));
    end;

    procedure GetUserSettings(UserSecurityId: Guid; var TempUserSettingsRecord: record "User Settings" temporary)
    var
        UserSettings: Codeunit "User Settings";
    begin
        UserSettings.GetUserSettings(Database.UserSecurityID(), TempUserSettingsRecord);
    end;

    #endregion
    procedure SetDependencies(SpecificDependencies: Interface "AppSource Product Manager Dependencies")
    begin
        Dependencies := SpecificDependencies;
        IsDependenciesSet := true;
    end;

    #region Product helpers
    /// <summary>
    /// Opens Microsoft AppSource web page for the region is specified in the UserSessionSettings or 'en-us' by default.
    /// </summary>
    procedure OpenAppSource()
    begin
        Init();
        Hyperlink(StrSubstNo(AppSourceUriLbl, Dependencies.GetFormatRegionOrDefault('')));
    end;

    /// <summary>
    /// Opens the AppSource product page in Microsoft AppSource, for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product to show in MicrosoftAppSource</param>
    procedure OpenAppInAppSource(UniqueProductIDValue: Text)
    begin
        Init();
        Hyperlink(StrSubstNo(AppSourceListingUriLbl, GetCurrentLanguageCultureName(), UniqueProductIDValue));
    end;

    /// <summary>
    /// Opens the AppSource product details page for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue"></param>
    internal procedure OpenProductDetailsPage(UniqueProductIDValue: Text)
    var
        ProductDetailsPage: Page "AppSource Product Details";
        ProductObject: JsonObject;
    begin
        ProductObject := GetProductDetails(UniqueProductIDValue);
        ProductDetailsPage.SetProduct(ProductObject);
        ProductDetailsPage.RunModal();
    end;

    /// <summary>
    /// Extracts the AppID from the Unique Product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product as defined in MicrosoftAppSource</param>
    /// <returns>AppID found in the Product ID</returns>
    /// <remarks>The AppSource unique product ID is specific to AppSource and combines different features while always ending with PAPID. and extension app id. Example: PUBID.mdcc1667400477212|AID.bc_converttemp_sample|PAPPID.9d314b3e-ffd3-41fd-8755-7744a6a790df</remarks>
    internal procedure ExtractAppIDFromUniqueProductID(UniqueProductIDValue: Text): Guid
    var
        AppIDPos: Integer;
        EmptyGuid: Guid;
    begin
        AppIDPos := StrPos(UniqueProductIDValue, 'PAPPID.');
        if (AppIDPos > 0) then
            exit(CopyStr(UniqueProductIDValue, AppIDPos + 7, 36));
        exit(EmptyGuid);
    end;

    /// <summary>
    /// Checks if the product can be installed or your are required to perform operations on AppSource before you can install the product.
    /// </summary>
    /// <param name="Plans">JSonArray representing the product plans</param>
    /// <returns>True if the product can be installed, otherwise false</returns>
    internal procedure CanInstallProductWithPlans(Plans: JsonArray): Boolean
    var
        PlanToken: JsonToken;
        PlanObject: JsonObject;
        PricingTypesToken: JsonToken;
        PricingTypes: JsonArray;
        PricingType: JsonToken;
    begin
        foreach PlanToken in Plans do begin
            PlanObject := PlanToken.AsObject();

            if PlanObject.Get('pricingTypes', PricingTypesToken) then
                if (PricingTypesToken.IsArray()) then begin
                    PricingTypes := PricingTypesToken.AsArray();
                    if PricingTypes.Count() = 0 then
                        exit(false); // No price structure, you need to contact the publisher

                    foreach PricingType in PricingTypes do
                        case LowerCase(PricingType.AsValue().AsText()) of
                            'free', // Free
                            'freetrial', // Free trial
                            'payg', // Pay as you go
                            'byol': // Bring your own license
                                exit(true);
                        end;
                end;
        end;

        exit(false);
    end;
    #endregion

    #region Market and language helper functions
    procedure GetCurrentLanguageCultureName(): Text
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetCultureName(GetCurrentUserLanguageID()));
    end;

    procedure ResolveMarketAndLanguage(var Market: Text; var LanguageName: Text)
    var
        Language: Codeunit Language;
        LanguageID, LocalID : integer;
    begin
        GetCurrentUserLanguageAnLocaleID(LanguageID, LocalID);

        // Marketplace API only supports two letter languages.
        LanguageName := Language.GetTwoLetterISOLanguageName(LanguageID);

        Market := '';
        if LocalID <> 0 then
            Market := ResolveMarketFromLanguageID(LocalID);
        if Market = '' then
            Market := CopyStr(Dependencies.GetApplicationFamily(), 1, 2);
        if (Market = '') or (Market = 'W1') then
            if not TryGetEnvironmentCountryLetterCode(Market) then
                Market := 'us';

        Market := EnsureValidMarket(Market);
        LanguageName := EnsureValidLanguage(LanguageName);
    end;

    procedure GetCurrentUserLanguageID(): Integer
    var
        TempUserSettings: Record "User Settings" temporary;
        Language: Codeunit Language;
        LanguageID: Integer;
    begin
        Dependencies.GetUserSettings(Database.UserSecurityID(), TempUserSettings);
        LanguageID := TempUserSettings."Language ID";
        if (LanguageID = 0) then
            LanguageID := Language.GetLanguageIdFromCultureName(Dependencies.GetPreferredLanguage());
        if (LanguageID = 0) then
            LanguageID := 1033; // Default to EN-US
        exit(LanguageID);
    end;

    local procedure GetCurrentUserLanguageAnLocaleID(var LanguageID: Integer; var LocaleID: Integer)
    var
        TempUserSettings: Record "User Settings" temporary;
        Language: Codeunit Language;
    begin
        Dependencies.GetUserSettings(Database.UserSecurityID(), TempUserSettings);
        LanguageID := TempUserSettings."Language ID";
        if (LanguageID = 0) then
            LanguageID := Language.GetLanguageIdFromCultureName(Dependencies.GetPreferredLanguage());
        if (LanguageID = 0) then
            LanguageID := 1033; // Default to EN-US

        LocaleID := TempUserSettings."Locale ID";
    end;

    [TryFunction]
    local procedure TryGetEnvironmentCountryLetterCode(var CountryLetterCode: Text)
    begin
        CountryLetterCode := Dependencies.GetCountryLetterCode();
    end;

    local procedure ResolveMarketFromLanguageID(LanguageID: Integer): Text
    var
        Language: Codeunit Language;
        SeperatorPos: Integer;
        LanguageAndRequestRegion: Text;
    begin
        LanguageAndRequestRegion := 'en';
        LanguageAndRequestRegion := Language.GetCultureName(LanguageID);
        SeperatorPos := StrPos(LanguageAndRequestRegion, '-');
        if SeperatorPos > 1 then
            exit(CopyStr(LanguageAndRequestRegion, SeperatorPos + 1, 2));

        exit('');
    end;

    /// <summary>
    /// Ensures that the market is valid for AppSource.
    /// </summary>
    /// <param name="Market">Market requested</param>
    /// <returns>The requested market if supported, otherwise us</returns>
    /// <remarks>See https://learn.microsoft.com/en-us/partner-center/marketplace/marketplace-geo-availability-currencies for supported markets</remarks>
    local procedure EnsureValidMarket(Market: Text): Text
    var
        NotSupportedNotification: Notification;
    begin
        case LowerCase(Market) of
            'af', 'al', 'dz', 'ad', 'ao', 'ar', 'am', 'au', 'at', 'az', 'bh', 'bd', 'bb', 'by', 'be', 'bz', 'bm', 'bo', 'ba', 'bw'
        , 'br', 'bn', 'bg', 'cv', 'cm', 'ca', 'ky', 'cl', 'cn', 'co', 'cr', 'ci', 'hr', 'cw', 'cy', 'cz', 'dk', 'do', 'ec', 'eg'
        , 'sv', 'ee', 'et', 'fo', 'fj', 'fi', 'fr', 'ge', 'de', 'gh', 'gr', 'gt', 'hn', 'hk', 'hu', 'is', 'in', 'id', 'iq', 'ie'
        , 'il', 'it', 'jm', 'jp', 'jo', 'kz', 'ke', 'kr', 'kw', 'kg', 'lv', 'lb', 'ly', 'li', 'lt', 'lu', 'mo', 'my', 'mt', 'mu'
        , 'mx', 'md', 'mc', 'mn', 'me', 'ma', 'na', 'np', 'nl', 'nz', 'ni', 'ng', 'mk', 'no', 'om', 'pk', 'ps', 'pa', 'py', 'pe'
        , 'ph', 'pl', 'pt', 'pr', 'qa', 'ro', 'ru', 'rw', 'kn', 'sa', 'sn', 'rs', 'sg', 'sk', 'si', 'za', 'es', 'lk', 'se', 'ch'
        , 'tw', 'tj', 'tz', 'th', 'tt', 'tn', 'tr', 'tm', 'ug', 'ua', 'ae', 'gb', 'us', 'vi', 'uy', 'uz', 'va', 've', 'vn', 'ye'
        , 'zm', 'zw':
                exit(LowerCase(Market));
            else begin
                NotSupportedNotification.Id := '0c0f2e34-e72f-4da4-a7d5-80b33653d13d';
                NotSupportedNotification.Message(StrSubstNo(UnsupportedMarketNotificationLbl, Market));
                NotSupportedNotification.Send();
                exit('us');
            end;
        end;
    end;

    /// <summary>
    /// Ensures that the language is valid for AppSource.
    /// </summary>
    /// <param name="Language">Language requested</param>
    /// <returns>The requested language if supported otherwise en</returns>
    /// <remarks>See https://learn.microsoft.com/en-us/rest/api/marketplacecatalog/dataplane/products/list?view=rest-marketplacecatalog-dataplane-2023-05-01-preview&amp;tabs=HTTP for supported languages</remarks>
    local procedure EnsureValidLanguage(Language: Text): Text
    var
        NotSupportedNotification: Notification;
    begin
        case LowerCase(Language) of
            'en', 'cs', 'de', 'es', 'fr', 'hu', 'it', 'ja', 'ko', 'nl', 'pl', 'pt-br', 'pt-pt', 'ru', 'sv', 'tr', 'zh-hans', 'zh-hant':
                exit(LowerCase(Language));
            else begin
                NotSupportedNotification.Id := '0664870f-bd05-46cc-9e98-cc338d7fdc64';
                NotSupportedNotification.Message(StrSubstNo(UnsupportedLanguageNotificationLbl, Language));
                NotSupportedNotification.Send();

                exit('en');
            end;
        end;
    end;
    #endregion

    /// <summary>
    /// Get all products from a remote server and adds them to the AppSource Product table.
    /// </summary>
    internal procedure GetProductsAndPopulateRecord(var AppSourceProductRec: record "AppSource Product"): Text
    var
        RestClient: Codeunit "Rest Client";
        NextPageLink: text;
    begin
        Init();
        NextPageLink := ConstructProductListUri();

        RestClient.Initialize();
        SetCommonHeaders(RestClient);

        repeat
            NextPageLink := DownloadAndAddNextPageProducts(NextPageLink, AppSourceProductRec, RestClient);
        until NextPageLink = '';
    end;

    /// <summary>
    /// Get specific product details from.
    /// </summary>
    local procedure GetProductDetails(UniqueProductIDValue: Text): JsonObject
    var
        RestClient: Codeunit "Rest Client";
        RequestUri: Text;
        ClientRequestID: Guid;
        TelemetryDictionary: Dictionary of [Text, Text];
    begin
        Init();
        ClientRequestID := CreateGuid();
        RequestUri := ConstructProductUri(UniqueProductIDValue);

        PopulateTelemetryDictionary(ClientRequestID, UniqueProductIDValue, RequestUri, TelemetryDictionary);
        Session.LogMessage('AL:AppSource-GetProduct', 'Requesting product details.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDictionary);

        RestClient.Initialize();
        SetCommonHeaders(RestClient);
        RestClient.SetDefaultRequestHeader('client-request-id', ClientRequestID);

        exit(Dependencies.GetAsJSon(RestClient, RequestUri).AsObject());
    end;

    local procedure DownloadAndAddNextPageProducts(NextPageLink: Text; var AppSourceProductRec: record "AppSource Product"; var RestClient: Codeunit "Rest Client"): Text
    var
        ResponseObject: JsonObject;
        ProductArray: JsonArray;
        ProductArrayToken: JsonToken;
        ProductToken: JsonToken;
        I: Integer;
        ClientRequestID: Guid;
        TelemetryDictionary: Dictionary of [Text, Text];
    begin
        ClientRequestID := CreateGuid();
        PopulateTelemetryDictionary(ClientRequestID, '', NextPageLink, TelemetryDictionary);
        Session.LogMessage('AL:AppSource-NextPageProducts', 'Requesting product list data', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDictionary);
        RestClient.SetDefaultRequestHeader('client-request-id', ClientRequestID);

        ResponseObject := Dependencies.GetAsJSon(RestClient, NextPageLink).AsObject();
        if (ResponseObject.Get('items', ProductArrayToken)) then begin
            ProductArray := ProductArrayToken.AsArray();
            for i := 0 to ProductArray.Count() do
                if (ProductArray.Get(i, ProductToken)) then
                    InsertProductFromObject(ProductToken.AsObject(), AppSourceProductRec);
        end;
        exit(AppSourceJsonUtilities.GetStringValue(ResponseObject, 'nextPageLink'));
    end;

    local procedure SetCommonHeaders(var RestClient: Codeunit "Rest Client")
    begin
        RestClient.SetDefaultRequestHeader('X-API-Key', GetAPIKey());
        RestClient.SetDefaultRequestHeader('x-ms-client-tenant-id', Dependencies.GetAadTenantID());
        RestClient.SetDefaultRequestHeader('x-ms-app', 'Dynamics 365 Business Central');
    end;

    local procedure ConstructProductListUri(): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
        Language: Text;
        Market: Text;
    begin
        ResolveMarketAndLanguage(Market, Language);

        UriBuilder.Init(CatalogProductsUriLbl);
        UriBuilder.AddQueryParameter(CatalogApiVersionQueryParamNameLbl, CatalogApiVersionQueryParamValueLbl);
        UriBuilder.AddQueryParameter(CatalogMarketQueryParamNameLbl, Market);
        UriBuilder.AddQueryParameter(CatalogLanguageQueryParamNameLbl, Language);

        UriBuilder.AddODataQueryParameter(CatalogApiFilterQueryParamNameLbl, 'productType eq ''DynamicsBC''');
        UriBuilder.AddODataQueryParameter(CatalogApiSelectQueryParamNameLbl, 'uniqueProductID,displayName,publisherID,publisherDisplayName,publisherType,ratingAverage,ratingCount,productType,popularity,privacyPolicyUri,lastModifiedDateTime');
        UriBuilder.AddODataQueryParameter(CatalogApiOrderByQueryParamNameLbl, 'displayName asc');

        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    local procedure ConstructProductUri(UniqueIdentifier: Text): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
        Language: Text;
        Market: Text;
    begin
        ResolveMarketAndLanguage(Market, Language);
        UriBuilder.Init(CatalogProductsUriLbl);
        UriBuilder.SetPath('products/' + UniqueIdentifier);
        UriBuilder.AddQueryParameter(CatalogApiVersionQueryParamNameLbl, CatalogApiVersionQueryParamValueLbl);
        UriBuilder.AddQueryParameter(CatalogMarketQueryParamNameLbl, Market);
        UriBuilder.AddQueryParameter(CatalogLanguageQueryParamNameLbl, Language);
        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    #region Telemetry helpers
    local procedure PopulateTelemetryDictionary(RequestID: Text; UniqueIdentifier: text; Uri: Text; var TelemetryDictionary: Dictionary of [Text, Text])
    begin
        PopulateTelemetryDictionary(RequestID, telemetryDictionary);
        TelemetryDictionary.Add('UniqueIdentifier', UniqueIdentifier);
        TelemetryDictionary.Add('Uri', Uri);
    end;

    local procedure PopulateTelemetryDictionary(RequestID: Text; var TelemetryDictionary: Dictionary of [Text, Text])
    begin
        TelemetryDictionary.Add('client-request-id', RequestID);
    end;
    #endregion

    local procedure InsertProductFromObject(Offer: JsonObject; var Product: Record "AppSource Product")
    begin
        Product.Init();
        Product.UniqueProductID := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'uniqueProductId'), 1, MaxStrLen(Product.UniqueProductID));
        Product.DisplayName := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'displayName'), 1, MaxStrLen(Product.DisplayName));
        Product.PublisherID := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'publisherId'), 1, MaxStrLen(Product.PublisherID));
        Product.PublisherDisplayName := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'publisherDisplayName'), 1, MaxStrLen(Product.PublisherDisplayName));
        Product.PublisherType := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'publisherType'), 1, MaxStrLen(Product.PublisherType));
        Product.RatingAverage := AppSourceJsonUtilities.GetDecimalValue(Offer, 'ratingAverage');
        Product.RatingCount := AppSourceJsonUtilities.GetIntegerValue(Offer, 'ratingCount');
        Product.ProductType := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'productType'), 1, MaxStrLen(Product.ProductType));
        Product.Popularity := AppSourceJsonUtilities.GetDecimalValue(Offer, 'popularity');
        Product.LastModifiedDateTime := AppSourceJsonUtilities.GetDateTimeValue(Offer, 'lastModifiedDateTime');

        Product.AppID := ExtractAppIDFromUniqueProductID(Product.UniqueProductID);

        // Insert, if it fails to insert due to the data (ex duplicate ids), ignore the error
        if not Product.Insert() then;
    end;

    [NonDebuggable]
    local procedure GetAPIKey(): SecretText
    var
        ApiKey: SecretText;
    begin
        Init();
        if not Dependencies.IsSaas() then
            Error(NotSupportedOnPremisesErrorLbl);

        Dependencies.GetAzureKeyVaultSecret('MS-AppSource-ApiKey', ApiKey);
        exit(ApiKey);
    end;

    local procedure Init()
    begin
        if not IsDependenciesSet then
            SetDefaultDependencyImplementation();
    end;

    local procedure SetDefaultDependencyImplementation()
    var
        DependencyInstance: Codeunit "AppSource Product Manager";
    begin
        SetDependencies(DependencyInstance);
        IsDependenciesSet := true;
    end;
}
