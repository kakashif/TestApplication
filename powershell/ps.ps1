Function ApplyXPath
{
    Param($xPath, [ref]$output)

    # because PowerShell treats parameters differently depending on where they come from...
    # a variable passed in as a param is treated as an array of 0 or more items
    # a string literal is treated as a string variable
    if (!($xPath.GetType().ToString() -EQ "System.String"))
    {
        $xPath = $xPath[0]
    }

    $result = [System.Xml.XPath.Extensions]::XPathSelectElement($xml, $xPath, $xmlns)
    if ($result -NE $null)
    {
        $output.Value = $result.Value
        return $true
    }

    return $false
}

Function ApplyXPathAndRegEx
{
    Param($xPath, $regExToApply, [ref]$output)

    # because PowerShell treats parameters differently depending on where they come from...
    if (!($xPath.GetType().ToString() -EQ "System.String"))
    {
        $xPath = $xPath[0]
    }


    $results = ""
    if (ApplyXPath $xPath ([ref]$results))
    {
        ForEach ($re in $regExToApply)
        {
            $results = $results -replace $re[0], $re[1]
        }
        $output.Value = $results
        return $true
    }
    return $false
}

Function AddAttribute
{
    Param($attributeName, $xPath)
    $xValue = ""
    $regEx = New-Object "System.Collections.Generic.List[string[]]"
    $regEx.Add(@("{\d+}$", ""))
    if (ApplyXPathAndRegEx $xPath $regEx ([ref]$xValue))
    {
        $attributes.Add($attributeName, $xValue)
    }
}

Function CreateSeoName()
{
    $seoName = ""
    if (!(ApplyXPath "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='f-seo-name']" ([ref]$seoName)))
    {
        $seoNameRegEx = New-Object "System.Collections.Generic.List[string[]]"
        $seoNameRegEx.Add(@("{\d+}$", ""))
        $seoNameRegEx.Add(@("[^a-z0-9\s_-]", ""))
        $seoNameRegEx.Add(@("(\s+-*\s*|\s*-*\s+)", "-"))
        if (!(ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_head" $seoNameRegEx  ([ref]$seoName)))
        {
            ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:head"  $seoNameRegEx ([ref]$seoName)
        }
    }
    
    if ($seoName -NE "")
    {
        $attributes.Add("seoname", $seoName.ToLower())
    }
}

Function CreateShortHed()
{
    $shortHed = ""
    $shortHedRegEx = New-Object "System.Collections.Generic.List[string[]]"
    $shortHedRegEx.Add(@("{\d+}$", ""))
    if (!(ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_headdeck" $shortHedRegEx  ([ref]$shortHed)))
    {
        if (!(ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_head" $shortHedRegEx  ([ref]$shortHed)))
        {
            ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:head" $shortHedRegEx ([ref]$shortHed)
        }
    }
    
    if ($shortHed -NE "")
    {
        $attributes.Add("short-hed", $shortHed)
    }
}

Function CreateSimpleAttributes()
{
    AddAttribute "seotitle" "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_summary__2"
    AddAttribute "hphoto-hed" "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_head__photo"
    AddAttribute "chatter" "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_summary__chatter"
    AddAttribute "metadescription" "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='meta_description']"
    AddAttribute "storyhighlights" "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='story_highlights']"
    AddAttribute "createdBy" "//object/children/object[@kind='Text']/attributes/attribute[@name='CreateOperator']"
    AddAttribute "createTime" "//object/children/object[@kind='Text']/attributes/attribute[@name='CreateTime']"
    AddAttribute "updatedBy" "//object/children/object[@kind='Text']/attributes/attribute[@name='RevOperator']"
    AddAttribute "updateTime" "//object/children/object[@kind='Text']/attributes/attribute[@name='LastRev']"
    AddAttribute "source" "//object/children/object[@kind='Text']/attributes/attribute[@name='IIM_Source']"
    #AddAttribute "" ""
    
}

Function CreateAttributes()
{
    # using DOT notation will probably confuse people therefore using XPath statements instead
    # here is equivalent of origin key using dot notation: ($xmlData.CCIObjects.object | Where kind -EQ "Budget").Attributes.Attribute | Where name -EQ "Id"
    
    # get origin key and cci id
    $originKey = ""
    if ((ApplyXPath "//object[@kind='Budget']/attributes/attribute[@name='Id']" ([ref]$originKey)))
    {
        $attributes.Add("originkey", $originKey)
        $attributes.Add("cciid", $originKey)
        $packageId = $originKey
    }
    else 
    {
        $errors.Add("origin key is null")
    }
    
    CreateSeoName
    CreateShortHed
    CreateSimpleAttributes
}

Function CreateFronts()
{
    $frontName = ""
    if (ApplyXPath "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='f-page1-front-1']" ([ref]$frontName))
    {
        $front = New-Object BusinessObjects.AssetSpace.Front
        $front.Location = $frontName
        $front.HoldUntilDate = $latestPublishedDate
        $content.Handling.PublishTo.Fronts += $front
    }
    
    if (ApplyXPath "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='f-page1-front-2']" ([ref]$frontName))
    {
        $front = New-Object BusinessObjects.AssetSpace.Front
        $front.Location = $frontName
        $content.Handling.PublishTo.Fronts += $front
    }
    
    if (ApplyXPath "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='f-page1-front-3']" ([ref]$frontName))
    {
        $front = New-Object BusinessObjects.AssetSpace.Front
        $front.Location = $frontName
        $content.Handling.PublishTo.Fronts += $front
    }
    
    if (ApplyXPath "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='f-page1-front-4']" ([ref]$frontName))
    {
        $front = New-Object BusinessObjects.AssetSpace.Front
        $front.Location = $frontName
        $content.Handling.PublishTo.Fronts += $front
    }
}

Function CreateHeadline()
{
    $headline = ""
    $headlineRegEx = New-Object "System.Collections.Generic.List[string[]]"
    $headlineRegEx.Add(@("{\d+}$", ""))
    if (!(ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_head" $headlineRegEx  ([ref]$headline)))
    {
        ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:head" $headlineRegEx ([ref]$headline)
    }
    
    if ($headline -NE "")
    {
        $content.Headline = $headline
    }
    else
    {
        $content.Headline = "NewsGate package " + $packageId
    }
}

Function CreateBody()
{

}

Function SetStaticProperties ($AssetGroupId, $SiteId, $PropertyId, $Type, $TypeId)
{
    $content.AssetGroupId = $AssetGroupId
    $content.SiteId = $SiteId
    $content.PropertyId = $PropertyId
    $content.Type = $Type
    $content.TypeId = $TypeId
    $content.Status = "draft"
}


# load external assemblies
 #[Reflection.Assembly]::Load("System.Xml.Linq, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
 [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq")
 [Reflection.Assembly]::LoadWithPartialName("System.Xml.XPath")
 

# get global parameters
[xml]$xmlDoc = Get-Content "C:\Users\kkhan\Documents\personal\github\TestApplication\powershell\sample_ng.xml"

$xml = [System.Xml.Linq.XElement]::Parse($xmlDoc.OuterXml)

# load name spaces
$xmlns = New-Object System.Xml.XmlNamespaceManager(New-Object System.Xml.NameTable)
$xmlns.AddNamespace("cci", "urn:schemas-ccieurope.com")
$xmlns.AddNamespace("ccit", "http://www.ccieurope.com/xmlns/ccimltables")
$xmlns.AddNamespace("ccix", "http://www.ccieurope.com/xmlns/ccimlextensions")
$xmlns.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")



# initialize other global variables
$packageId = ""
$body = ""
$attributes = @{}
$errors = New-Object System.Collections.Generic.List[string]
$latestPublishedDate = ""
if (!(ApplyXPath "//object[@kind='Budget']/attributes/attribute[@name='PublicationDate']" ([ref]$latestPublishedDate)))
{
    $latestPublishedDate = Get-Date
}


#initialize Content object and set default properties
SetStaticProperties 1 1 1 "text" 1

#create attributes and other properties
CreateAttributes
CreateFronts
CreateHeadline

#$attributes.GetEnumerator() | Sort-Object Value -descending