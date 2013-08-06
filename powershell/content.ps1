Function CreateSeoName()
{
    $seoName = ""
    if (!(ApplyXPath "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='f-seo-name']" ([ref]$seoName)))
    {
        $seoNameRegEx = New-Object System.Collections.Generic.List[string[]]
        $seoNameRegEx.Add(@("{\d+}$", ""))
        $seoNameRegEx.Add(@("[^a-z0-9\s_-]", ""))
        $seoNameRegEx.Add(@("(\s+-*\s*|\s*-*\s+)", "-"))
        if (!(ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_head" $seoNameRegEx  ([ref]$seoName)))
        {
            ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:head"  $seoNameRegEx ([ref]$seoName)
        }
    }
    
    if ($seoName -ne "")
    {
        $attributes.Add("seoname", $seoName.ToLower())
    }
}

Function CreateShortHed()
{
    $shortHed = ""
    $shortHedRegEx = New-Object System.Collections.Generic.List[string[]]
    $shortHedRegEx.Add(@("{\d+}$", ""))
    if (!(ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_headdeck" $shortHedRegEx  ([ref]$shortHed)))
    {
        if (!(ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_head" $shortHedRegEx  ([ref]$shortHed)))
        {
            ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:head" $shortHedRegEx ([ref]$shortHed)
        }
    }
    
    if ($shortHed -ne "")
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
        $asset.Handling.PublishTo.Fronts += $front
    }
    
    if (ApplyXPath "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='f-page1-front-2']" ([ref]$frontName))
    {
        $front = New-Object BusinessObjects.AssetSpace.Front
        $front.Location = $frontName
        $asset.Handling.PublishTo.Fronts += $front
    }
    
    if (ApplyXPath "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='f-page1-front-3']" ([ref]$frontName))
    {
        $front = New-Object BusinessObjects.AssetSpace.Front
        $front.Location = $frontName
        $asset.Handling.PublishTo.Fronts += $front
    }
    
    if (ApplyXPath "//object/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object[@kind='OnlineArticle']/attributes/attribute[@name='f-page1-front-4']" ([ref]$frontName))
    {
        $front = New-Object BusinessObjects.AssetSpace.Front
        $front.Location = $frontName
        $asset.Handling.PublishTo.Fronts += $front
    }
}

Function CreateHeadline()
{
    $headline = ""
    $headlineRegEx = New-Object System.Collections.Generic.List[string[]]
    $headlineRegEx.Add(@("{\d+}$", ""))
    if (!(ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_head" $headlineRegEx  ([ref]$headline)))
    {
        ApplyXPathAndRegEx "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:head" $headlineRegEx ([ref]$headline)
    }
    
    if ($headline -ne "")
    {
        $asset.Headline = $headline
        $hasHeadline = "true"
    }
    else
    {
        $asset.Headline = "NewsGate package " + $packageId
        $hasHeadline = "false"
    }
}

Function CreateBody()
{
    $bodyRegEx = New-Object System.Collections.Generic.List[string[]]
    $bodyRegEx.Add(@("<ccix:([^>]*)>", "<cci:$1/>"))
    $bodyRegEx.Add(@("<ccit:([^>]*)>", "<cci:$1>"))
    $bodyRegEx.Add(@("</ccit:([^>]*)>", "</cci:$1>"))
    $bodyRegEx.Add(@("<cci:body[^>]*>", "<body>"))
    $bodyRegEx.Add(@("</cci:body>", "</body>"))
    $bodyRegEx.Add(@("<cci:web class=`"character`" displayname=`"web`" href=`"([^\\`"]*)`" name=`"web`">(.*?)</cci:web>", "<a href=`"$1`">$2</a>"))
    $bodyRegEx.Add(@("<cci:italic [^>]*>(.*?)</cci:italic>", "<i>$1</i>"))
    $bodyRegEx.Add(@("<cci:bold [^>]*>(.*?)</cci:bold>", "<b>$1</b>"))
    $bodyRegEx.Add(@("<cci:underline [^>]*>(.*?)</cci:underline>", "<u>$1</u>"))
    $bodyRegEx.Add(@("<cci:web_type [^>]*>(.*?)</cci:web_type>", ""))
    $bodyRegEx.Add(@("<cci:table [^>]*>", "<table>"))
    $bodyRegEx.Add(@("</cci:table>", "</table>"))
    $bodyRegEx.Add(@("<cci:tbody>", "<tbody>"))
    $bodyRegEx.Add(@("</cci:tbody>", "</tbody>"))
    $bodyRegEx.Add(@("<cci:tr[^>]*>", "<tr>"))
    $bodyRegEx.Add(@("</cci:tr>", "</tr>"))
    $bodyRegEx.Add(@("<cci:td[^>]*/>", "<td />"))
    $bodyRegEx.Add(@("<cci:td[^>]*>", "<td>"))
    $bodyRegEx.Add(@("</cci:td>", "</td>"))
    $bodyRegEx.Add(@("<cci:command value=`"240`"[^>]*/>", "<br />"))
    $bodyRegEx.Add(@("<cci:command[^>]*/>", ""))
    $bodyRegEx.Add(@("<cci:bullet_list class=`"paragraph`" displayname=`"bullet_list`" name=`"bullet_list`">", "<ul>"))
    $bodyRegEx.Add(@("</cci:bullet_list>", "</ul>"))
    $bodyRegEx.Add(@("<cci:[^>]*/>", ""))
    $bodyRegEx.Add(@("<cci:[^>]*>", "<p>"))
    $bodyRegEx.Add(@("</cci:[^>]*>", "</p>"))
    # keep these special characters replace in this order.  See single quote vs. double quote why
    # now would be a good time to bring out the giant reg ex list from FeedFetcher
    #$bodyRegEx.Add(@('â€”', "&#8212;"))
    #$bodyRegEx.Add(@("â€™", "'"))
    #$bodyRegEx.Add(@("â€œ|â€", "`""))
    
    $result = [System.Xml.XPath.Extensions]::XPathSelectElement($xml, "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:body", $xmlns)
    if ($result -NE $null)
    {
        $result = $result.ToString()
        ForEach ($re in $bodyRegEx)
        {
            $result = $result -replace $re[0], $re[1]
        }
        $asset.Body = New-Object BusinessObjects.ContentSpace.Body
        $asset.Body.SetFromXml($result)
    }
    else
    {
         #$error.Add("body is null")
    }
}

Function TransformSsts($ssts)
{
    if ($ssts -eq "")
    {
        return ""
    }
    if($ssts -match "\[([^\]]+)\]")
    {
        return $matches[1]
    }
    else
    {
        return $ssts.Replace("[", "").Replace("]", "")
    }
}

Function CreateSsts()
{
    # get the values between square brackets if they exist
    # if not then replace the lingering opening or closing square brackets with empty string
    $ssts1 = ""
    $ssts2 = ""
    $ssts3 = ""
    $ssts4 = ""
    $ssts5 = ""

    ApplyXPath "//object[@kind='Budget']/attributes/attribute[@name='Path1']" ([ref]$ssts1)
    ApplyXPath "//object[@kind='Budget']/attributes/attribute[@name='Path2']" ([ref]$ssts2)
    ApplyXPath "//object[@kind='Budget']/attributes/attribute[@name='Path3']" ([ref]$ssts3)
    ApplyXPath "//object[@kind='Budget']/attributes/attribute[@name='Path4']" ([ref]$ssts4)
    ApplyXPath "//object[@kind='Budget']/attributes/attribute[@name='Path5']" ([ref]$ssts5)

    $asset.Handling.PublishTo.Ssts.Section = TransformSsts($ssts1)
    $asset.Handling.PublishTo.Ssts.Subsection = TransformSsts($ssts2)
    $asset.Handling.PublishTo.Ssts.Topic = TransformSsts($ssts3)
    $asset.Handling.PublishTo.Ssts.Subtopic = TransformSsts($ssts4)
    $asset.Handling.PublishTo.Ssts.StorySubject = TransformSsts($ssts5)
}

Function CreateBrief()
{
    $brief = ""
    if (!(ApplyXPath "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:mm_summary" ([ref]$brief)))
    {
        ApplyXPath "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:body/cci:p[1]" ([ref]$brief)
        if ($brief.Length -ge 117)
        {
            $brief = $brief.Substring(0, 117) + "..."
        }
    }
    $attributes.Add("brief", $brief)
}

Function CreateDate()
{
    $embargoDate = ""
    if (!(ApplyXPath "//object[@kind='Budget']/children/object[@kind='OnlineArticle']/content/data/CCIObjects/object/attributes/attribute[@name='embargo']" ([ref]$embargoDate)))
    {
        $embargoDate = $latestPublishedDate
    }

    $asset.Dates = New-Object BusinessObjects.AssetSpace.Dates
    $asset.Dates.Embargodate = $embargoDate

}

Function CreateByline()
{
    $bylineXml = [System.Xml.XPath.Extensions]::XPathSelectElement($xml, "//object/children/object[@kind='Text']/content/data/cci:ccitext/cci:byline", $xmlns)
    $bylineXmlCopy = New-Object System.Xml.Linq.XElement($bylineXml)
    $bylineProcessed = false
    if (($bylineXml -ne $null) -and ($bylineXml.Value -ne ""))
    {
        [System.Xml.Linq.XElement]$bylineXml = $bylineXml
        # simple by line with an author and its source
        $bylineName = [System.Xml.XPath.Extensions]::XPathSelectElement($bylineXml, "//cci:byline_name", $xmlns)
        $bylineSource = [System.Xml.XPath.Extensions]::XPathSelectElement($bylineXml, "//cci:byline_credit", $xmlns)
        if ($bylineName -ne $null)
        {
            $contributors.Add(($bylineName.Value, $bylineSource.Value))
            $bylineProcessed = true
        }
        else
        {
            # check to see if the source information is wrapped in a p tag or just sitting outside of XML nodes instead of byline_credit.
            # This takes care of the following case:
            # byline
            #   byline_name: author name
            #   p (or no node): source name
            # remove the byline and check if any text is left.  This will asssume that the leftover is source
            $bylineName = [System.Xml.XPath.Extensions]::XPathSelectElement($bylineXmlCopy, "//cci:byline_name", $xmlns)
            if ($bylineName -ne $null)
            {
                $bylineName.Remove()
                # if left over text in byline node. At this point we probably do not care if bylineNameXml is empty as if it is empty. This simply means assign an
                # empty string to a variable where we are going to endup with empty string anyway when there is no author name.
                if ($bylineXmlCopy.Value -ne "")
                {
                    $contributors.Add(($bylineName.Value, $bylineXmlCopy.Value))
                    $bylineProcessed = true
                }
            }
            else
            {
                # there is no author node...perhaps it is divided by P tags. Here again the assumption is that the first P tag will contain the author name
                # and the second will contain the source name (is it safe to ignore the rest?)
                $pTag1 = [System.Xml.XPath.Extensions]::XPathSelectElement($bylineXmlCopy, "//cci:p[1]", $xmlns)
                $pTag2 = [System.Xml.XPath.Extensions]::XPathSelectElement($bylineXmlCopy, "//cci:p[2]", $xmlns)
                
                if ($pTag1 -ne $null -and $pTag1.Value -ne "")
                {
                    if ($pTag2 -ne $null -and $pTag2.Value -ne "")
                    {
                        $contributors.Add(($pTag1.Value, $pTag2.Value))
                        $bylineProcessed = true
                    }
                }
            }
        }

        if (!$bylineProcessed)
        {
            # the byline is completely mess, try to take care of it using commas
            # else ignore it completely and make it an override
            $bylineSplint = $bylineXml.Value.Split(",")
            if ($bylineSplint.Count -eq 2)
            {
                $contributors.Add(($bylineSplint[0], $bylineSplint[1]))
            }
            else
            {
                $contributors.Add(($bylineXml.Value, ""))
            }
        }

    }
    else
    {
        $errors.Add("Byline is empty or null.")
    }

}

Function CreateMiscProperties()
{
    $iimSource = ""
    if (ApplyXPath "//object/children/object[@kind='Text']/attributes/attribute[@name='IIM_Source']" ([ref]$iimSource))
    {
        $asset.Source = $iimSource
    }
    else
    {
        $asset.Source = $source
    }
}

# load external assemblies
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
$packageId = ""
$attributes = @{}
$errors = New-Object System.Collections.Generic.List[String]
#contributoor array with index 0 containing name and 1 containing source
$contributors = New-Object System.Collections.Generic.List[string[]]
$hasHeadline = ""
$isValidProductType = ""
$latestPublishedDate = ""
$finalContentStatus = "draft"
if (!(ApplyXPath "//object[@kind='Budget']/attributes/attribute[@name='PublicationDate']" ([ref]$latestPublishedDate)))
{
    $latestPublishedDate = Get-Date
}

#initialize asset text object and set default properties
SetStaticProperties $assetGroupId $siteId $propertyId "text" 9 "draft"

#create attributes and other properties
CreateAttributes
CreateFronts
CreateHeadline
CreateBody
CreateSsts
CreateBrief
CreateDate
CreateByline
CreateMiscProperties