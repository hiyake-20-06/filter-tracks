# ============================================================
#  Tool-Filter.ps1  -  Giao diện lọc dung lượng ổ C:
#  CHỈ LỌC - KHÔNG CÓ CHỨC NĂNG XÓA.
#  Nhóm An toàn / Xem xét: chọn được để đưa vào "Danh sách của tôi"
#  Nhóm Không xóa (protected): KHÓA - không thể chọn.
# ============================================================
param(
    [switch]$SelfTest,
    [switch]$DataTest,
    [string]$Shot,
    [string]$DataPath
)

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml

# ---------- Đường dẫn tương đối: chạy được từ bất kỳ thư mục nào ----------
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$toolDir = $scriptDir
if ((Split-Path $toolDir -Leaf) -eq 'resources') { $toolDir = Split-Path $toolDir -Parent }
$dataDir = Join-Path $toolDir 'data'
$jsonPath = Join-Path $dataDir 'index.json'
if ($DataPath) { $jsonPath = $DataPath }
$scanScript = Join-Path $scriptDir 'Scan.ps1'
if (-not (Test-Path -LiteralPath $scanScript)) { $scanScript = Join-Path $toolDir 'Scan.ps1' }

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tool Filter - Ổ C:" Height="840" Width="1400"
        WindowStartupLocation="CenterScreen" Background="#F4F7FB"
        FontFamily="Segoe UI" UseLayoutRounding="True">

  <Window.Resources>
    <SolidColorBrush x:Key="Ink" Color="#0F172A"/>
    <SolidColorBrush x:Key="Muted" Color="#64748B"/>
    <SolidColorBrush x:Key="Line" Color="#E2E8F0"/>
    <SolidColorBrush x:Key="Accent" Color="#2563EB"/>

    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="#FFFFFF"/>
      <Setter Property="CornerRadius" Value="12"/>
      <Setter Property="BorderBrush" Value="#E2E8F0"/>
      <Setter Property="BorderThickness" Value="1"/>
    </Style>

    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Background" Value="#FFFFFF"/>
      <Setter Property="Foreground" Value="#0F172A"/>
      <Setter Property="BorderBrush" Value="#CBD5E1"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="14,9"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="8" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#EFF6FF"/>
                <Setter TargetName="b" Property="BorderBrush" Value="#93C5FD"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="b" Property="Background" Value="#DBEAFE"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.45"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="BtnPrimary" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="#2563EB"/>
      <Setter Property="Foreground" Value="#FFFFFF"/>
      <Setter Property="BorderBrush" Value="#2563EB"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}"
                    CornerRadius="8" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#1D4ED8"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.45"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="CatBtn" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="Margin" Value="0,0,0,8"/>
      <Setter Property="Padding" Value="12,10"/>
    </Style>

    <Style x:Key="SearchBox" TargetType="TextBox">
      <Setter Property="Background" Value="#FFFFFF"/>
      <Setter Property="BorderBrush" Value="#CBD5E1"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="10,9"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
              <ScrollViewer x:Name="PART_ContentHost" Margin="4,0"/>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid Margin="18,16,18,12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- HEADER -->
    <Border Grid.Row="0" Style="{StaticResource Card}" Padding="18,14" Margin="0,0,0,14">
      <Grid>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <Border Width="42" Height="42" CornerRadius="10" Background="#EFF6FF" Margin="0,0,14,0">
            <TextBlock Text="C:" FontSize="18" FontWeight="Bold" Foreground="#2563EB"
                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <StackPanel>
            <TextBlock Text="TOOL FILTER" FontSize="11" FontWeight="Bold" Foreground="#2563EB" />
            <TextBlock Text="Lọc dung lượng ổ C:" FontSize="20" FontWeight="SemiBold" Foreground="#0F172A"/>
            <TextBlock x:Name="TxtSub" Text="Đang tải dữ liệu..." FontSize="12" Foreground="#64748B" Margin="0,2,0,0"/>
          </StackPanel>
        </StackPanel>

        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
          <Button x:Name="BtnReload" Content="Tải lại dữ liệu" Style="{StaticResource Btn}" Margin="0,0,8,0"/>
          <Button x:Name="BtnRescan" Content="Quét lại ổ C:" Style="{StaticResource Btn}" Margin="0,0,8,0"/>
          <Button x:Name="BtnHelp" Content="Hướng dẫn" Style="{StaticResource Btn}"/>
        </StackPanel>
      </Grid>
    </Border>

    <!-- BODY -->
    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="270"/>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="350"/>
      </Grid.ColumnDefinitions>

      <!-- LEFT: categories -->
      <StackPanel Grid.Column="0" Margin="0,0,14,0">
        <Border Style="{StaticResource Card}" Padding="14">
          <StackPanel>
            <TextBlock Text="DANH MỤC LỌC" FontSize="11" FontWeight="Bold" Foreground="#64748B" Margin="2,0,0,10"/>

            <Button x:Name="BtnAll" Style="{StaticResource CatBtn}" Tag="all">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <Ellipse Grid.Column="0" Width="10" Height="10" Fill="#334155" Margin="0,0,10,0" VerticalAlignment="Center"/>
                <TextBlock Grid.Column="1" Text="Tất cả" FontSize="13" FontWeight="SemiBold"/>
                <TextBlock Grid.Column="2" x:Name="CntAll" Text="0" FontSize="12" Foreground="#64748B"/>
              </Grid>
            </Button>

            <Button x:Name="BtnSafe" Style="{StaticResource CatBtn}" Tag="safe">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <Ellipse Grid.Column="0" Width="10" Height="10" Fill="#16A34A" Margin="0,0,10,0" VerticalAlignment="Center"/>
                <StackPanel Grid.Column="1">
                  <TextBlock Text="An toàn" FontSize="13" FontWeight="SemiBold"/>
                  <TextBlock x:Name="SumSafe" Text="0 GB" FontSize="11" Foreground="#16A34A"/>
                </StackPanel>
                <TextBlock Grid.Column="2" x:Name="CntSafe" Text="0" FontSize="12" Foreground="#64748B"/>
              </Grid>
            </Button>

            <Button x:Name="BtnReview" Style="{StaticResource CatBtn}" Tag="review">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <Ellipse Grid.Column="0" Width="10" Height="10" Fill="#D97706" Margin="0,0,10,0" VerticalAlignment="Center"/>
                <StackPanel Grid.Column="1">
                  <TextBlock Text="Xem xét" FontSize="13" FontWeight="SemiBold"/>
                  <TextBlock x:Name="SumReview" Text="0 GB" FontSize="11" Foreground="#D97706"/>
                </StackPanel>
                <TextBlock Grid.Column="2" x:Name="CntReview" Text="0" FontSize="12" Foreground="#64748B"/>
              </Grid>
            </Button>

            <Button x:Name="BtnProtected" Style="{StaticResource CatBtn}" Tag="protected">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <Ellipse Grid.Column="0" Width="10" Height="10" Fill="#DC2626" Margin="0,0,10,0" VerticalAlignment="Center"/>
                <StackPanel Grid.Column="1">
                  <TextBlock Text="Không xóa  ·  khóa" FontSize="13" FontWeight="SemiBold"/>
                  <TextBlock x:Name="SumProtected" Text="0 GB" FontSize="11" Foreground="#DC2626"/>
                </StackPanel>
                <TextBlock Grid.Column="2" x:Name="CntProtected" Text="0" FontSize="12" Foreground="#64748B"/>
              </Grid>
            </Button>

            <Rectangle Height="1" Fill="#E2E8F0" Margin="0,6,0,12"/>
            <TextBlock Text="Quy tắc" FontSize="11" FontWeight="Bold" Foreground="#64748B" Margin="2,0,0,6"/>
            <TextBlock TextWrapping="Wrap" FontSize="11.5" Foreground="#475569" LineHeight="18">
              <Run Text="• "/><Run Text="An toàn" FontWeight="Bold" Foreground="#16A34A"/><Run Text=": cache/bản cũ, tự tạo lại."/>
              <LineBreak/>
              <Run Text="• "/><Run Text="Xem xét" FontWeight="Bold" Foreground="#D97706"/><Run Text=": là dữ liệu của bạn."/>
              <LineBreak/>
              <Run Text="• "/><Run Text="Không xóa" FontWeight="Bold" Foreground="#DC2626"/><Run Text=": hệ thống/dữ liệu quan trọng, bị khóa."/>
            </TextBlock>
          </StackPanel>
        </Border>

        <Border Style="{StaticResource Card}" Padding="14" Margin="0,12,0,0">
          <StackPanel>
            <TextBlock Text="TRẠNG THÁI KHÓA" FontSize="11" FontWeight="Bold" Foreground="#64748B" Margin="2,0,0,8"/>
            <TextBlock x:Name="TxtLockInfo" TextWrapping="Wrap" FontSize="11.5" Foreground="#475569" LineHeight="18"
                       Text="Mục &quot;Không xóa&quot; bị khóa trong tool: không thể chọn, không thể đưa vào danh sách. Tool không có chức năng xóa."/>
          </StackPanel>
        </Border>
      </StackPanel>

      <!-- CENTER: grid -->
      <Border Grid.Column="1" Style="{StaticResource Card}" Padding="14">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <Grid Grid.Row="0" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Grid Grid.Column="0">
              <TextBox x:Name="TxtSearch" Style="{StaticResource SearchBox}"
                       ToolTip="Gõ tên hoặc đường dẫn để lọc..."/>
              <TextBlock x:Name="TxtSearchHint" Text="Tìm theo tên hoặc đường dẫn…"
                         Margin="12,0,0,0" VerticalAlignment="Center"
                         Foreground="#94A3B8" FontSize="13" IsHitTestVisible="False"/>
            </Grid>
            <Button x:Name="BtnClearSearch" Grid.Column="1" Content="Xóa lọc" Style="{StaticResource Btn}" Margin="8,0,0,0"/>
          </Grid>

          <DataGrid x:Name="Grid1" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True"
                    CanUserAddRows="False" CanUserDeleteRows="False" CanUserResizeRows="False"
                    HeadersVisibility="Column" GridLinesVisibility="Horizontal"
                    HorizontalGridLinesBrush="#F1F5F9" BorderThickness="0"
                    Background="#FFFFFF" RowHeaderWidth="0" SelectionMode="Extended"
                    FontSize="12.5" RowHeight="34" EnableRowVirtualization="True">
            <DataGrid.Columns>
              <DataGridTextColumn Header="Khóa" Binding="{Binding LockText}" Width="50" SortMemberPath="Locked">
                <DataGridTextColumn.ElementStyle>
                  <Style TargetType="TextBlock">
                    <Setter Property="Foreground" Value="#DC2626"/>
                    <Setter Property="FontSize" Value="10"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                    <Setter Property="HorizontalAlignment" Value="Center"/>
                  </Style>
                </DataGridTextColumn.ElementStyle>
              </DataGridTextColumn>
              <DataGridTextColumn Header="Tên" Binding="{Binding Name}" Width="200" SortMemberPath="Name"/>
              <DataGridTextColumn Header="Dung lượng" Binding="{Binding SizeText}" Width="90" SortMemberPath="Bytes">
                <DataGridTextColumn.ElementStyle>
                  <Style TargetType="TextBlock">
                    <Setter Property="HorizontalAlignment" Value="Right"/>
                    <Setter Property="FontWeight" Value="SemiBold"/>
                  </Style>
                </DataGridTextColumn.ElementStyle>
              </DataGridTextColumn>
              <DataGridTextColumn Header="Nhóm" Binding="{Binding CatText}" Width="85" SortMemberPath="Category"/>
              <DataGridTextColumn Header="Đường dẫn" Binding="{Binding Path}" Width="210" SortMemberPath="Path"/>
            </DataGrid.Columns>
            <DataGrid.RowStyle>
              <Style TargetType="DataGridRow">
                <Setter Property="Background" Value="#FFFFFF"/>
                <Setter Property="Foreground" Value="#0F172A"/>
                <Style.Triggers>
                  <DataTrigger Binding="{Binding Category}" Value="safe">
                    <Setter Property="Background" Value="#F0FDF4"/>
                  </DataTrigger>
                  <DataTrigger Binding="{Binding Category}" Value="review">
                    <Setter Property="Background" Value="#FFFBEB"/>
                  </DataTrigger>
                  <DataTrigger Binding="{Binding Category}" Value="protected">
                    <Setter Property="Background" Value="#F8FAFC"/>
                    <Setter Property="Foreground" Value="#94A3B8"/>
                  </DataTrigger>
                  <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#DBEAFE"/>
                    <Setter Property="Foreground" Value="#0F172A"/>
                  </Trigger>
                </Style.Triggers>
              </Style>
            </DataGrid.RowStyle>
            <DataGrid.ColumnHeaderStyle>
              <Style TargetType="DataGridColumnHeader">
                <Setter Property="Background" Value="#F8FAFC"/>
                <Setter Property="Foreground" Value="#475569"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="FontSize" Value="11.5"/>
                <Setter Property="Padding" Value="10,8"/>
                <Setter Property="BorderBrush" Value="#E2E8F0"/>
                <Setter Property="BorderThickness" Value="0,0,0,1"/>
              </Style>
            </DataGrid.ColumnHeaderStyle>
          </DataGrid>

          <Border Grid.Row="2" Background="#F8FAFC" CornerRadius="8" Padding="12,9" Margin="0,10,0,0">
            <StackPanel>
              <TextBlock x:Name="TxtDetailTitle" Text="Chọn một dòng để xem giải thích" FontSize="12.5" FontWeight="SemiBold" Foreground="#0F172A" TextTrimming="CharacterEllipsis"/>
              <TextBlock x:Name="TxtDetailReason" Text="" FontSize="11.5" Foreground="#475569" TextWrapping="Wrap" Margin="0,3,0,0"/>
              <TextBlock x:Name="TxtDetailAction" Text="" FontSize="11.5" Foreground="#2563EB" TextWrapping="Wrap" Margin="0,2,0,0"/>
            </StackPanel>
          </Border>

          <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,10,0,0">
            <Button x:Name="BtnAdd" Content="Thêm vào danh sách của tôi" Style="{StaticResource BtnPrimary}"/>
            <Button x:Name="BtnOpen" Content="Mở trong Explorer" Style="{StaticResource Btn}" Margin="8,0,0,0"/>
            <Button x:Name="BtnCopy" Content="Sao chép đường dẫn" Style="{StaticResource Btn}" Margin="8,0,0,0"/>
            <TextBlock x:Name="TxtStatus" Text="" FontSize="12" Foreground="#64748B" VerticalAlignment="Center" Margin="14,0,0,0"/>
          </StackPanel>
        </Grid>
      </Border>

      <!-- RIGHT: my list -->
      <Border Grid.Column="2" Style="{StaticResource Card}" Padding="14" Margin="14,0,0,0">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <StackPanel Grid.Row="0">
            <TextBlock Text="DANH SÁCH CỦA TÔI" FontSize="11" FontWeight="Bold" Foreground="#64748B"/>
            <TextBlock Text="Bạn tự xóa các mục này bằng tay (Explorer)." FontSize="11.5" Foreground="#64748B" Margin="0,4,0,0" TextWrapping="Wrap"/>
          </StackPanel>

          <Border Grid.Row="1" Background="#EFF6FF" CornerRadius="8" Padding="10,8" Margin="0,10,0,10">
            <StackPanel>
              <TextBlock x:Name="TxtMyCount" Text="0 mục" FontSize="13" FontWeight="SemiBold" Foreground="#1E40AF"/>
              <TextBlock x:Name="TxtMySize" Text="0 GB" FontSize="11.5" Foreground="#3B82F6"/>
            </StackPanel>
          </Border>

          <ListBox x:Name="LstMine" Grid.Row="2" BorderThickness="0" Background="Transparent"
                   SelectionMode="Extended"
                   ScrollViewer.HorizontalScrollBarVisibility="Disabled">
            <ListBox.ItemTemplate>
              <DataTemplate>
                <Border Background="#F8FAFC" CornerRadius="6" Padding="8,6" Margin="0,0,0,6">
                  <StackPanel>
                    <TextBlock Text="{Binding SizeText}" FontSize="11" FontWeight="SemiBold" Foreground="#2563EB"/>
                    <TextBlock Text="{Binding Path}" FontSize="11" Foreground="#334155" TextWrapping="Wrap"/>
                  </StackPanel>
                </Border>
              </DataTemplate>
            </ListBox.ItemTemplate>
          </ListBox>

          <StackPanel Grid.Row="3" Margin="0,10,0,0">
            <Button x:Name="BtnExport" Content="Xuất danh sách (CSV)" Style="{StaticResource Btn}" Margin="0,0,0,8"/>
            <Button x:Name="BtnRemove" Content="Bỏ khỏi danh sách" Style="{StaticResource Btn}" Margin="0,0,0,8"/>
            <Button x:Name="BtnOpenMine" Content="Mở thư mục đã chọn" Style="{StaticResource Btn}"/>
          </StackPanel>
        </Grid>
      </Border>
    </Grid>

    <!-- FOOTER -->
    <TextBlock Grid.Row="2" Margin="4,10,0,0" FontSize="11" Foreground="#94A3B8"
               Text="Tool chỉ đọc và lọc. Không có chức năng xóa. Mục KHÓA không thể chọn. Dung lượng đo bằng robocopy (số theo file — WinSxS hardlink có thể làm cao hơn thực tế). Tổng nhóm Không xóa tính theo dung lượng ổ đang dùng."/>
  </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$win = [Windows.Markup.XamlReader]::Load($reader)

# Tạo thư mục dữ liệu + biểu tượng cửa sổ (nếu có)
try { $null = New-Item -ItemType Directory -Force -Path $dataDir } catch { }
$icoPath = Join-Path $scriptDir 'app.ico'
if (-not (Test-Path -LiteralPath $icoPath)) { $icoPath = Join-Path $toolDir 'build\app.ico' }
if (Test-Path -LiteralPath $icoPath) {
    try {
        $dec = [System.Windows.Media.Imaging.BitmapDecoder]::Create([Uri]$icoPath, 'None', 'OnLoad')
        $win.Icon = $dec.Frames[0]
    } catch { }
}

if ($SelfTest) {
    Write-Host "SELFTEST OK: XAML parsed, window created."
    exit 0
}

# ---------- helpers ----------
function Get-Element($name) { $win.FindName($name) }

$script:AllItems  = @()
$script:ViewItems = @()
$script:MyList    = New-Object System.Collections.ArrayList
$script:Filter    = 'all'

$TxtSub        = Get-Element 'TxtSub'
$TxtSearch     = Get-Element 'TxtSearch'
$TxtSearchHint = Get-Element 'TxtSearchHint'
$TxtStatus     = Get-Element 'TxtStatus'
$TxtDetailTitle= Get-Element 'TxtDetailTitle'
$TxtDetailReason= Get-Element 'TxtDetailReason'
$TxtDetailAction= Get-Element 'TxtDetailAction'
$TxtLockInfo   = Get-Element 'TxtLockInfo'
$Grid1         = Get-Element 'Grid1'
$LstMine       = Get-Element 'LstMine'
$TxtMyCount    = Get-Element 'TxtMyCount'
$TxtMySize     = Get-Element 'TxtMySize'
$CntAll        = Get-Element 'CntAll'
$CntSafe       = Get-Element 'CntSafe'
$CntReview     = Get-Element 'CntReview'
$CntProtected  = Get-Element 'CntProtected'
$SumSafe       = Get-Element 'SumSafe'
$SumReview     = Get-Element 'SumReview'
$SumProtected  = Get-Element 'SumProtected'

function Fmt([double]$b) {
    if ($b -ge 1GB) { return ("{0:n2} GB" -f ($b / 1GB)) }
    if ($b -ge 1MB) { return ("{0:n0} MB" -f ($b / 1MB)) }
    return ("{0:n0} KB" -f ($b / 1KB))
}

function Load-Data {
    if (-not (Test-Path $jsonPath)) {
        $TxtSub.Text = "Chưa có dữ liệu — bấm 'Quét lại ổ C:' (khoảng 2 phút) để bắt đầu."
        $Grid1.ItemsSource = @()
        $TxtStatus.Text = 'Chưa có dữ liệu'
        $TxtDetailTitle.Text = 'Chào mừng đến Tool Filter'
        $TxtDetailReason.Text = 'Công cụ chỉ đọc, giúp bạn rà soát dung lượng ổ C: theo 3 nhóm: An toàn / Xem xét / Không xóa.'
        $TxtDetailAction.Text = "Bấm 'Quét lại ổ C:' ở góc phải để quét lần đầu."
        return
    }
    try {
        $raw = Get-Content -Raw -Encoding UTF8 $jsonPath | ConvertFrom-Json
    } catch {
        $TxtSub.Text = "Không đọc được index.json: $($_.Exception.Message)"
        return
    }

    $script:AllItems = @($raw.Items | ForEach-Object {
        [pscustomobject]@{
            Name     = $_.Name
            Path     = $_.Path
            Bytes    = [double]$_.Bytes
            SizeText = $_.SizeText
            Files    = [int]$_.Files
            Category = $_.Category
            CatText  = $_.CatText
            Locked   = [bool]$_.Locked
            LockText = if ($_.Locked) { 'KHÓA' } else { '' }
            Reason   = $_.Reason
            Action   = $_.Action
        }
    })

    $v = $raw.Volume
    $usedTxt = ''
    if ($v.PSObject.Properties.Name -contains 'UsedGB') { $usedTxt = ("Dùng {0:n2} GB  ·  " -f $v.UsedGB) }
    $TxtSub.Text = ("C: {0:n2} GB  ·  {1}Trống {2:n2} GB ({3:n1}%)  ·  Quét {4}  ·  {5} mục" -f `
        $v.SizeGB, $usedTxt, $v.FreeGB, $v.FreePct, $raw.Generated, @($script:AllItems).Count)

    $t = $raw.Totals
    $SumSafe.Text      = Fmt $t.SafeBytes
    $SumReview.Text    = Fmt $t.ReviewBytes
    $SumProtected.Text = Fmt $t.ProtectedBytes
    $CntSafe.Text      = $t.SafeItems
    $CntReview.Text    = $t.ReviewItems
    $CntProtected.Text = $t.ProtectedItems
    $CntAll.Text       = $script:AllItems.Count

    $TxtLockInfo.Text = ("{0} mục bị khóa (KHÓA) — không thể chọn. Tool không có chức năng xóa; bạn tự xóa bằng Explorer sau khi xuất danh sách." -f $t.ProtectedItems)

    Update-View
}

function Update-View {
    if ($TxtSearchHint) {
        $TxtSearchHint.Visibility = if ($TxtSearch.Text.Length -gt 0) { 'Collapsed' } else { 'Visible' }
    }
    $items = $script:AllItems
    if ($script:Filter -ne 'all') { $items = @($items | Where-Object { $_.Category -eq $script:Filter }) }
    $q = $TxtSearch.Text
    if ($q -and $q.Trim().Length -gt 0) {
        $q = $q.Trim().ToLower()
        $items = @($items | Where-Object { $_.Path.ToLower().Contains($q) -or $_.Name.ToLower().Contains($q) })
    }
    $script:ViewItems = @($items)
    $Grid1.ItemsSource = $script:ViewItems
    $TxtStatus.Text = ("{0} mục" -f $script:ViewItems.Count)
}

function Add-Mine($item) {
    if ($item.Locked -or $item.Category -eq 'protected') {
        [System.Windows.MessageBox]::Show("Mục này đang KHÓA (Không xóa).`n`n" + $item.Path + "`n`nTool không cho phép chọn mục bảo vệ.", "Đã khóa", 'OK', 'Warning') | Out-Null
        return $false
    }
    foreach ($x in $script:MyList) { if ($x.Path -eq $item.Path) { return $false } }
    [void]$script:MyList.Add([pscustomobject]@{
        Path = $item.Path; SizeText = $item.SizeText; Bytes = $item.Bytes
        CatText = $item.CatText; Reason = $item.Reason
    })
    return $true
}

function Refresh-Mine {
    $LstMine.ItemsSource = @($script:MyList)
    $sum = 0.0
    foreach ($x in $script:MyList) { $sum += $x.Bytes }
    $TxtMyCount.Text = ("{0} mục" -f $script:MyList.Count)
    $TxtMySize.Text  = Fmt $sum
}

# ---------- events ----------
$BtnAll = Get-Element 'BtnAll'
$BtnSafe = Get-Element 'BtnSafe'
$BtnReview = Get-Element 'BtnReview'
$BtnProtected = Get-Element 'BtnProtected'

foreach ($b in @($BtnAll, $BtnSafe, $BtnReview, $BtnProtected)) {
    $b.Add_Click({
        param($s, $e)
        $script:Filter = $s.Tag
        Update-View
    })
}

$TxtSearch.Add_TextChanged({ Update-View })
(Get-Element 'BtnClearSearch').Add_Click({ $TxtSearch.Text = ''; Update-View })

$Grid1.Add_SelectionChanged({
    if ($Grid1.SelectedItems.Count -eq 1) {
        $it = $Grid1.SelectedItems[0]
        $TxtDetailTitle.Text  = ("{0}   ·   {1}" -f $it.SizeText, $it.Path)
        $TxtDetailReason.Text = "Vì sao: " + $it.Reason
        $TxtDetailAction.Text = "Gợi ý: " + $it.Action
    } elseif ($Grid1.SelectedItems.Count -gt 1) {
        $TxtDetailTitle.Text = ("Đã chọn {0} mục" -f $Grid1.SelectedItems.Count)
        $TxtDetailReason.Text = "Bấm 'Thêm vào danh sách của tôi' để gom các mục này."
        $TxtDetailAction.Text = "Mục KHÓA sẽ bị từ chối."
    }
})

(Get-Element 'BtnAdd').Add_Click({
    $n = 0; $locked = 0
    foreach ($it in @($Grid1.SelectedItems)) {
        if ($it.Category -eq 'protected') { $locked++ }
        elseif (Add-Mine $it) { $n++ }
    }
    Refresh-Mine
    if ($locked -gt 0 -and $n -eq 0) {
        [System.Windows.MessageBox]::Show("$locked mục đang KHÓA nên không thể thêm.`nChỉ nhóm An toàn / Xem xét mới chọn được.", "Bị khóa", 'OK', 'Warning') | Out-Null
    } else {
        $TxtStatus.Text = ("Đã thêm {0} mục{1}" -f $n, $(if($locked -gt 0){" (bỏ qua $locked mục khóa)"}else{""}))
    }
})

(Get-Element 'BtnOpen').Add_Click({
    foreach ($it in @($Grid1.SelectedItems | Select-Object -First 3)) {
        if (Test-Path -LiteralPath $it.Path -PathType Container) { Start-Process explorer.exe $it.Path }
        else { Start-Process explorer.exe "/select,`"$($it.Path)`"" }
    }
})

$Grid1.Add_MouseDoubleClick({
    $it = $Grid1.SelectedItem
    if ($null -eq $it) { return }
    if (Test-Path -LiteralPath $it.Path -PathType Container) { Start-Process explorer.exe $it.Path }
    elseif (Test-Path -LiteralPath $it.Path) { Start-Process explorer.exe "/select,`"$($it.Path)`"" }
})

(Get-Element 'BtnCopy').Add_Click({
    if ($Grid1.SelectedItems.Count -gt 0) {
        $txt = ($Grid1.SelectedItems | ForEach-Object { $_.Path }) -join "`r`n"
        [System.Windows.Clipboard]::SetText($txt)
        $TxtStatus.Text = "Đã sao chép đường dẫn."
    }
})

(Get-Element 'BtnRemove').Add_Click({
    $sel = $LstMine.SelectedItems
    foreach ($x in @($sel)) { $script:MyList.Remove($x) }
    Refresh-Mine
})

(Get-Element 'BtnExport').Add_Click({
    if ($script:MyList.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Danh sách đang trống.", "Thông báo", 'OK', 'Information') | Out-Null
        return
    }
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = "CSV (*.csv)|*.csv"
    $dlg.FileName = "danh-sach-xoa-" + (Get-Date -Format 'yyyyMMdd-HHmm') + ".csv"
    $dlg.InitialDirectory = $dataDir
    if ($dlg.ShowDialog() -eq $true) {
        $script:MyList | Select-Object Path, SizeText, CatText, @{n='Bytes';e={[int64]$_.Bytes}}, Reason |
            Export-Csv -Path $dlg.FileName -NoTypeInformation -Encoding UTF8
        $TxtStatus.Text = "Đã xuất: $($dlg.FileName)"
        Start-Process explorer.exe "/select,`"$($dlg.FileName)`""
    }
})

(Get-Element 'BtnOpenMine').Add_Click({
    foreach ($x in @($LstMine.SelectedItems)) {
        if (Test-Path -LiteralPath $x.Path -PathType Container) { Start-Process explorer.exe $x.Path }
        else { Start-Process explorer.exe "/select,`"$($x.Path)`"" }
    }
})

(Get-Element 'BtnReload').Add_Click({ Load-Data })

(Get-Element 'BtnRescan').Add_Click({
    $msg = "Quét lại toàn bộ ổ C: (chỉ đọc).`n`nQuá trình mất khoảng 2-4 phút và mở một cửa sổ riêng.`nKhi cửa sổ đóng, bấm 'Tải lại dữ liệu'."
    if ([System.Windows.MessageBox]::Show($msg, "Quét lại", 'OKCancel', 'Question') -eq 'OK') {
        if (Test-Path -LiteralPath $scanScript) {
            Start-Process powershell.exe -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$scanScript`""
        } else {
            [System.Windows.MessageBox]::Show("Không tìm thấy Scan.ps1 cạnh Tool-Filter.ps1.`nHãy giải nén đầy đủ thư mục ứng dụng.", "Thiếu tệp", 'OK', 'Error') | Out-Null
        }
    }
})

(Get-Element 'BtnHelp').Add_Click({
    $h = @"
TOOL FILTER - Ổ C:

1. Chọn nhóm ở cột trái: An toàn / Xem xét / Không xóa.
2. Gõ vào ô tìm kiếm để lọc theo tên hoặc đường dẫn.
3. Chọn dòng (giữ Ctrl để chọn nhiều) rồi bấm
   "Thêm vào danh sách của tôi".
4. Mục KHÓA (Không xóa) KHÔNG thể chọn.
5. Bấm "Xuất danh sách (CSV)" để lưu.
6. Bạn TỰ XÓA bằng tay trong Explorer.

Tool KHÔNG có chức năng xóa.
Dữ liệu quét: $jsonPath
"@
    [System.Windows.MessageBox]::Show($h, "Hướng dẫn", 'OK', 'Information') | Out-Null
})

Refresh-Mine
Load-Data

if ($DataTest) {
    Write-Host ("DATA TEST: items={0} | safe={1} ({2}) | review={3} ({4}) | protected={5} ({6})" -f `
        $script:AllItems.Count, $SumSafe.Text, $CntSafe.Text, $SumReview.Text, $CntReview.Text, $SumProtected.Text, $CntProtected.Text)
    Write-Host ("HEADER: {0}" -f $TxtSub.Text)
    Write-Host ("GRID: {0} dong dang hien thi" -f $script:ViewItems.Count)
    Write-Host ("LOCK: {0}" -f $TxtLockInfo.Text)
    Write-Host ("COLUMNS: " + (($Grid1.Columns | ForEach-Object { "{0}={1:n0}" -f $(if($_.Header){$_.Header}else{'lock'}), $_.ActualWidth }) -join ' | '))
    $script:Filter = 'safe'; Update-View
    Write-Host ("FILTER safe -> {0} dong" -f $script:ViewItems.Count)
    $script:Filter = 'protected'; Update-View
    Write-Host ("FILTER protected -> {0} dong" -f $script:ViewItems.Count)
    $script:Filter = 'all'; Update-View
    $sample = @($script:AllItems | Where-Object { $_.Category -eq 'safe' } | Select-Object -First 1)
    if ($sample.Count -gt 0) {
        $ok = Add-Mine $sample[0]; Refresh-Mine
        Write-Host ("ADD TEST: ok={0} | danh sach={1} | tong={2}" -f $ok, $script:MyList.Count, $TxtMySize.Text)
    }
    Write-Host ("SEARCH TEST: 'capcut' -> ")
    $TxtSearch.Text = 'capcut'
    Write-Host ("  {0} dong" -f $script:ViewItems.Count)
    $TxtSearch.Text = ''
    exit 0
}

if ($Shot) {
    $win.Show()
    $win.UpdateLayout()
    $Grid1.UpdateLayout()
    $w = [int]$win.ActualWidth; $h = [int]$win.ActualHeight
    $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap $w, $h, 96, 96, ([System.Windows.Media.PixelFormats]::Pbgra32)
    $rtb.Render($win)
    $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))
    $fs = [System.IO.File]::Create($Shot)
    $enc.Save($fs)
    $fs.Close()
    $win.Close()
    Write-Host ("SHOT OK: {0} ({1}x{2})" -f $Shot, $w, $h)
    exit 0
}

[void]$win.ShowDialog()
