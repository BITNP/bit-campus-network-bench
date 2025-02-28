#!/usr/bin/env pwsh

function Test-IpInSubnet {
    param (
        [string]$ipAddress,  # 需要检测的 IP 地址
        [string]$subnet,     # 子网地址
        [string]$subnetMask  # 子网掩码
    )

    $ip = [System.Net.IPAddress]::Parse($ipAddress)
    $subnetIP = [System.Net.IPAddress]::Parse($subnet)
    $mask = [System.Net.IPAddress]::Parse($subnetMask)

    $ipBytes = $ip.GetAddressBytes()
    $subnetBytes = $subnetIP.GetAddressBytes()
    $maskBytes = $mask.GetAddressBytes()

    $networkBytes = @()
    for ($i = 0; $i -lt $ipBytes.Length; $i++) {
        $networkBytes += $ipBytes[$i] -band $maskBytes[$i]
    }

    $networkAddress = [System.Net.IPAddress]::new($networkBytes)
    $subnetAddress = [System.Net.IPAddress]::Parse($subnet)
    if ($networkAddress.ToString() -eq $subnetAddress.ToString()) {
        return $true
    } else {
        return $false
    }
}

$global:isIPv6Available = $true

$global:isRunningOnWindows = $false

if (($PSEdition -eq "Desktop") -or ($PSEdition -eq "Core" -and $PSVersionTable.Platform -eq "Win32NT")) {
    $global:isRunningOnWindows = $true
}

# 先检查一下10.0.0.55
$pingResult = Test-Connection -ComputerName "10.0.0.55" -Count 1 -Quiet
if (-not $pingResult) {
    throw "10.0.0.55 不可达，到校园网的连接不正确"
}

# 检查一下登录了没有
$pingResult = Test-Connection -ComputerName "10.0.0.1" -Count 1 -Quiet
if (-not $pingResult) {
    throw "内网不可用，请登录校园网"
}

Write-Host "本机的校园网接入正确"

Write-Host "检查校园网DNS解析"
$null = Resolve-DnsName -Name "www.baidu.com" -Server "10.0.0.9" -DnsOnly
$null = Resolve-DnsName -Name "www.baidu.com" -Server "10.0.0.10" -DnsOnly
$null = Resolve-DnsName -Name "www.baidu.com" -Server "10.0.0.11" -DnsOnly
$null = Resolve-DnsName -Name "www.baidu.com" -Server "10.0.0.12" -DnsOnly
$null = Resolve-DnsName -Name "www.baidu.com" -Server "10.0.0.13" -DnsOnly
$null = Resolve-DnsName -Name "www.baidu.com" -Server "10.0.0.14" -DnsOnly
Write-Host "检查校园网DNS解析完毕，若没有输出报错则说明正常"

# 检查一下ipv6情况 2001:da8:204:1205::22 is mirror.bit.edu.cn
$pingResult = Test-Connection -ComputerName "2001:da8:204:1205::22" -Count 1 -Quiet
if (-not $pingResult) {
    $global:isIPv6Available = $false
    Write-Warning "IPv6不可用，因此不进行IPv6测试"
}

Write-Host "获取校园网接入信息"

# IPV4
if ($global:isRunningOnWindows) {
    $defaultRoute4 = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric,ifMetric)[0]
    $defaultGateway4 = $defaultRoute4.NextHop
    $defaultInterfaceIndex4 = $defaultRoute4.InterfaceIndex

    $defaultAdapter4 = Get-NetAdapter -InterfaceIndex $defaultInterfaceIndex4
    $adapterName4 = $defaultAdapter4.Name
    $adapterIP4 = (Get-NetIPAddress -InterfaceAlias $adapterName4 | Where-Object {$_.AddressFamily -eq 'IPv4'}).IPAddress
} else {
    $defaultRoute4 = (ip route | grep default)
    $defaultGateway4 = (echo $defaultRoute4 | awk '{print $3}')
    $adapterName4 = (echo $defaultRoute4 | awk '{print $5}')
    $adapterIP4 = (ip -4 addr show $adapterName4 | grep inet | head -n 1 | awk '{print $2}' | cut -d/ -f1)
}

Write-Host "IPv4 默认网卡: $adapterName4"
Write-Host "IPv4 默认网卡 IP 地址: $adapterIP4"
Write-Host "IPv4 默认网关: $defaultGateway4"
if (-not (Test-IpInSubnet -ipAddress $adapterIP4 -subnet "10.0.0.0" -subnetMask "255.0.0.0")) {
    Write-Warning "IPv4地址 $adapterIP4 不像是校园网地址（可能是接入了自己的路由器）"
}

$IPv4OutIP = (Invoke-WebRequest -Uri "http://4.ipw.cn").Content

Write-Host "IPv4 网络出口是 $IPv4OutIP"

Write-Host "测试常见网站"

$commonWebsites4News = "www.qq.com","www.163.com"
$commonWebsites4Video = "www.bilibili.com","www.iqiyi.com","www.douyin.com","www.douyu.com","www.huya.com"
$commonWebsites4Mirror = "mirrors.tuna.tsinghua.edu.cn","mirrors.ustc.edu.cn","mirrors.nju.edu.cn","mirror.sjtu.edu.cn","mirrors.bfsu.edu.cn"

$commonWebsites4 = $commonWebsites4News + $commonWebsites4Video + $commonWebsites4Mirror

foreach ($website in $commonWebsites4) {
    Test-Connection -IPv4 -ComputerName $website
}


#IPV6
if (-not $global:isIPv6Available) {
    exit
}

if ($global:isRunningOnWindows) {
    $defaultRoute6 = (Get-NetRoute -DestinationPrefix '::/0' | Sort-Object RouteMetric,ifMetric)[0]
    $defaultGateway6 = $defaultRoute6.NextHop
    $defaultInterfaceIndex6 = $defaultRoute6.InterfaceIndex

    $defaultAdapter6 = Get-NetAdapter -InterfaceIndex $defaultInterfaceIndex6
    $adapterName6 = $defaultAdapter6.Name
    $adapterIP6 = ((Get-NetIPAddress -InterfaceAlias $adapterName6 | Where-Object {$_.AddressFamily -eq 'IPv6' -and $_.PrefixOrigin -ne 'WellKnown'}).IPAddress)[0]
} else {
    $defaultRoute6 = (ip -6 route | grep default)
    $defaultGateway6 = (echo $defaultRoute6 | awk '{print $3}')
    $adapterName6 = (echo $defaultRoute6 | awk '{print $5}')
    $adapterIP6 = (ip -6 addr show $adapterName6 | grep inet6 | head -n 1 | awk '{print $2}' | cut -d/ -f1)
}

Write-Host "IPv6 默认网卡: $adapterName6"
Write-Host "IPv6 默认网卡 IP 地址: $adapterIP6"
Write-Host "IPv6 默认网关: $defaultGateway6"
if (-not (Test-IpInSubnet -ipAddress $adapterIP6 -subnet "2001:da8:204::" -subnetMask "ffff:ffff:ffff::")) {
    Write-Warning "IPV6地址 $adapterIP6 看起来不是校园网地址（可能是接入了自己的路由器）"
}

$IPv6OutIP = (Invoke-WebRequest -Uri "http://6.ipw.cn").Content

Write-Host "IPv6 网络出口是 $IPv6OutIP"

$DualStackOutIP = (Invoke-WebRequest -Uri "http://test.ipw.cn").Content

Write-Host "双栈 网络出口是 $DualStackOutIP"

Write-Host "测试常见网站"

$commonWebsites6News = "www.qq.com","www.163.com"
$commonWebsites6Video = "www.iqiyi.com","www.douyin.com","www.douyu.com","www.huya.com"
$commonWebsites6Mirror = "mirrors.tuna.tsinghua.edu.cn","mirrors.ustc.edu.cn","mirrors.nju.edu.cn","mirror.sjtu.edu.cn","mirrors.bfsu.edu.cn"

$commonWebsites6 = $commonWebsites6News + $commonWebsites6Video + $commonWebsites6Mirror
foreach ($website in $commonWebsites6) {
    Test-Connection -IPv6 -ComputerName $website
}

