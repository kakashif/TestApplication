Function CreateAttributes()
{
    # using DOT notation will probably confuse people therefore using XPath statements instead
    # here is equivalent of origin key using dot notation: ($xmlData.CCIObjects.object | Where kind -EQ "Budget").Attributes.Attribute | Where name -EQ "Id"
    
    # get origin key and cci id
    $originalFileName = ""
    if ((ApplyXPathAttribute "./content/link" "reference" ([ref]$originalFileName)))
    {
        $attributes.Add("originalfilename", $originalFileName)
    }
    else 
    {
        $errors.Add("file name not available")
        #throw "file name not available"
    }

    $originKey = ""
    if (!(ApplyXPathAttribute "." "id" ([ref]$originKey)))
    {
        $attributes.Add("cutline", $originKey)
    }

    $cutline = ""
    if (!(ApplyXPath "./attributes/attribute[@name='CaptionText']" ([ref]$cutline)))
    {
        ApplyXPath "./attributes/attribute[@name='IIM_Caption']" ([ref]$cutline)
    }
    $attributes.Add("cutline", $cutline)
    
    $credit = ""
    if (!(ApplyXPath "./attributes/attribute[@name='IIM_Byline']" ([ref]$credit)))
    {
        if (!(ApplyXPath "./attributes/attribute[@name='IIM_Credit']" ([ref]$credit)))
        {
            ApplyXPath "./attributes/attribute[@name='CaptionCredit']" ([ref]$credit)
        }
    }
    $attributes.Add("credit", $credit)
}

Function CreateAudit()
{
    $publishDate = ""
    if (!(ApplyXPath "./attributes/attribute[@name='IIM_CreationDate']" ([ref]$publishDate)))
    {
        $publishDate = $dateNow
    }

    $asset.Dates = New-Object BusinessObjects.AssetSpace.Dates
    $asset.Dates.Embargodate = $publishDate
    $attributes.Add("datephototaken", $publishDate)
    
    $createdBy = ""
    if (!(ApplyXPath "./attributes/attribute[@name='CreateOperator']" ([ref]$createdBy)))
    {
        $attributes.Add("createdBy", $createdBy)
    }
    
    $updatedBy = ""
    if (!(ApplyXPath "./attributes/attribute[@name='RevOperator']" ([ref]$updatedBy)))
    {
        if (!(ApplyXPath "./attributes/attribute[@name='CreateOperator']" ([ref]$updatedBy)))
        {
            $attributes.Add("updatedBy", $updatedBy)
        }
    }
}

Function CreateImageName()
{
    $regEx = New-Object System.Collections.Generic.List[string[]]
    $regEx.Add(@("[^a-zA-Z0-9-.]", ""))
    $baseName = ""
    if (!(ApplyXPathAndRegEx "./attributes/attribute[@name='Name']" $regEx ([ref]$baseName)))
    {
        ApplyXPathAttributeAndRegEx "./content/link" "reference" $regEx ([ref]$baseName)
    }
    $attributes.Add("basename", $baseName)
}


# load external assemblies
[Reflection.Assembly]::LoadWithPartialName("System")
[Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq")
[Reflection.Assembly]::LoadWithPartialName("System.Xml.XPath")

# get global parameters
#[xml]$xmlDoc = Get-Content "C:\Users\kkhan\Documents\personal\github\TestApplication\powershell\sample_ng.xml"
#$xml = [System.Xml.Linq.XElement]::Parse($xmlDoc.OuterXml)
[System.Xml.Linq.XElement]$xml = $xml
$asset = $asset
$propertyId = $propertyId
$source = $source
$assetGroupId = $assetGroupId
$siteId = $siteId

# load name spaces
$xmlns = New-Object System.Xml.XmlNamespaceManager(New-Object System.Xml.NameTable)
$xmlns.AddNamespace("cci", "urn:schemas-ccieurope.com")
$xmlns.AddNamespace("ccit", "http://www.ccieurope.com/xmlns/ccimltables")
$xmlns.AddNamespace("ccix", "http://www.ccieurope.com/xmlns/ccimlextensions")
$xmlns.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

# initialize other global variables
$attributes = @{}
$errors = New-Object System.Collections.Generic.List[String]
$dateNow = Get-Date -Format s


#initialize asset text object and set default properties
SetStaticProperties $assetGroupId $siteId $propertyId "image" 1 "published"

#create attributes and other properties
CreateAttributes
CreateAudit
CreateImageName