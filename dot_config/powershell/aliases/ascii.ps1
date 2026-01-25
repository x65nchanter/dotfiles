function ascii
{
    $table = for ($i = 32; $i -le 127; $i++)
    {
        [PSCustomObject]@{
            Dec = $i
            Hex = '0x{0:X2}' -f $i
            Char = [char]$i
        }
    }
    $table | Format-Table -AutoSize
}
