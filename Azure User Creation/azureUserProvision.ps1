# Connect to Azure AD
Connect-AzureAD

# Import users from CSV
$users = Import-Csv -Path "users.csv"

foreach ($user in $users) {
    $passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $passwordProfile.Password = $user.Password
    $passwordProfile.ForceChangePasswordNextLogin = $true

    # Create the user
    $newUser = New-AzureADUser -UserPrincipalName $user.UserPrincipalName `
                               -DisplayName $user.DisplayName `
                               -PasswordProfile $passwordProfile `
                               -AccountEnabled $true `
                               -MailNickname $user.MailNickname

    Write-Host "User created: $($newUser.ObjectId)"

    # Assign directory role
    $roleName = $user.Role

    if ($roleName) {
        $role = Get-AzureADDirectoryRole | Where-Object { $_.DisplayName -eq $roleName }

        # If role not activated, activate it
        if (-not $role) {
            $roleTemplate = Get-AzureADDirectoryRoleTemplate | Where-Object { $_.DisplayName -eq $roleName }
            if ($roleTemplate) {
                Enable-AzureADDirectoryRole -RoleTemplateId $roleTemplate.ObjectId
                $role = Get-AzureADDirectoryRole | Where-Object { $_.DisplayName -eq $roleName }
            } else {
                Write-Host "Role '$roleName' not found."
                continue
            }
        }

        Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $newUser.ObjectId
        Write-Host "Assigned role '$roleName' to $($user.UserPrincipalName)"
    }
}
