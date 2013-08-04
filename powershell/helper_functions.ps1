Function ApplyXPath
{
    Param([String]$xPath, [ref]$output)


    $result = [System.Xml.XPath.Extensions]::XPathSelectElement($xml, $xPath, $xmlns)
    if (($result -ne $null) -and ($result.Value -ne ""))
    {
        $output.Value = $result.Value
        return $true
    }

    return $false
}

Function ApplyXPathAndRegEx
{
    Param([String]$xPath, $regExToApply, [ref]$output)

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
    $regEx = New-Object System.Collections.Generic.List[string[]]
    $regEx.Add(@("{\d+}$", ""))
    if (ApplyXPathAndRegEx $xPath $regEx ([ref]$xValue))
    {
        $attributes.Add($attributeName, $xValue)
    }
}

Function SetStaticProperties($assetGroupId, $siteId, $propertyId, $type, $typeId, $status)
{
    $asset.AssetGroupId = $assetGroupId
    $asset.SiteId = $siteId
    $asset.PropertyId = $propertyId
    $asset.Type = $type
    $asset.TypeId = $typeId
    $asset.Status = $status
}