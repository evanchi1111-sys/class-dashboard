param([int]$port=8766,[switch]$NoOpen)
# 班級儀表板：本機小型網頁伺服器（只給這台電腦使用，不會對外開放）
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$mime=@{'.html'='text/html; charset=utf-8';'.js'='text/javascript; charset=utf-8';'.css'='text/css; charset=utf-8';'.json'='application/json; charset=utf-8';'.jpg'='image/jpeg';'.jpeg'='image/jpeg';'.png'='image/png';'.gif'='image/gif';'.svg'='image/svg+xml';'.webp'='image/webp';'.ico'='image/x-icon';'.txt'='text/plain; charset=utf-8'}
$l=New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:$port/")
try{$l.Start()}catch{
  Write-Host "無法啟動：網址埠號 $port 可能已被使用（可能已經開了另一個儀表板視窗）。" -ForegroundColor Yellow
  Write-Host "如果已經有儀表板的黑色視窗，請直接用瀏覽器開啟 http://localhost:$port/"
  Read-Host "按 Enter 關閉"; exit
}
Write-Host "班級儀表板已啟動。請不要關閉這個視窗，關閉就等於結束儀表板。" -ForegroundColor Green
Write-Host "網址：http://localhost:$port/"
if(-not $NoOpen){Start-Process "http://localhost:$port/"}
while($l.IsListening){
  $ctx=$l.GetContext()
  try{
    $rel=[uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
    if($rel -eq ''){$rel='index.html'}
    $full=[System.IO.Path]::GetFullPath((Join-Path $root $rel))
    if($full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path $full -PathType Leaf)){
      $ext=[System.IO.Path]::GetExtension($full).ToLower()
      $ct=$mime[$ext]; if(-not $ct){$ct='application/octet-stream'}
      $bytes=[System.IO.File]::ReadAllBytes($full)
      $ctx.Response.ContentType=$ct
      $ctx.Response.Headers.Add('Cache-Control','no-cache')
      $ctx.Response.ContentLength64=$bytes.Length
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    } else { $ctx.Response.StatusCode=404 }
  }catch{ try{$ctx.Response.StatusCode=500}catch{} }
  finally{ try{$ctx.Response.Close()}catch{} }
}
