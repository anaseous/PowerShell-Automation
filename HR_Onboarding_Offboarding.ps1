# Function to create a new user in Active Directory
Function New-ADUserFromTemplate {
    param(
        [string]$TemplateSamAccountName,
        [string]$NewFirstName,
        [string]$NewLastName,
        [string]$EmployeeNumber,
        [string]$Department,
        [string]$Position
    )
    # Import the Active Directory module
    Import-Module ActiveDirectory

    # Generate the new username and email
    $SamAccountName = "$($NewFirstName.Substring(0,1).ToLower())$($NewLastName.ToLower())"
    $Email = "$($NewFirstName.ToLower()).$($NewLastName.ToLower())@companydomain.com"

    # Get the template user
    $TemplateUser = Get-ADUser -Filter {SamAccountName -eq $TemplateSamAccountName} -Properties MemberOf, Department, Title

    if ($TemplateUser -eq $null) {
        Write-Host "Template user '$TemplateSamAccountName' not found." -ForegroundColor Red
        return
    }

    # Create the new user
    $NewUser = New-ADUser -Name "$NewFirstName $NewLastName" `
        -GivenName $NewFirstName `
        -Surname $NewLastName `
        -SamAccountName $SamAccountName `
        -UserPrincipalName $Email `
        -EmailAddress $Email `
        -Department $Department `
        -Title $Position `
        -EmployeeID $EmployeeNumber `
        -AccountPassword (ConvertTo-SecureString "P@ssword123" -AsPlainText -Force) `
        -Enabled $true `
        -PassThru

    # Add the new user to the same groups as the template user
    foreach ($Group in $TemplateUser.MemberOf) {
        Add-ADGroupMember -Identity $Group -Members $NewUser
    }

    Write-Host "User $($NewUser.SamAccountName) created successfully!" -ForegroundColor Green
}

# Main Menu
Function ShowMenu {
    Clear-Host
    Write-Host "HR Onboarding/Offboarding Tool" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host "1. Onboard a new user"
    Write-Host "2. Offboard an existing user"
    Write-Host "3. Exit"
}

# Offboarding Function
Function Offboard-ADUser {
    param(
        [string]$SamAccountName
    )
    $User = Get-ADUser -Filter {SamAccountName -eq $SamAccountName} -Properties *
    if ($User) {
        Disable-ADAccount -Identity $User
        Move-ADObject -Identity $User.DistinguishedName -TargetPath "OU=DisabledUsers,DC=YourDomain,DC=com"
        Write-Host "User $SamAccountName has been offboarded." -ForegroundColor Green
    } else {
        Write-Host "User not found!" -ForegroundColor Red
    }
}

# Start Script
do {
    ShowMenu
    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            # Onboard User
            $Template = Read-Host "Enter the template username"
            $FirstName = Read-Host "Enter new employee's first name"
            $LastName = Read-Host "Enter new employee's last name"
            $EmpNumber = Read-Host "Enter employee number"
            $Dept = Read-Host "Enter department name"
            $Pos = Read-Host "Enter position"
            New-ADUserFromTemplate -TemplateSamAccountName $Template `
                                   -NewFirstName $FirstName `
                                   -NewLastName $LastName `
                                   -EmployeeNumber $EmpNumber `
                                   -Department $Dept `
                                   -Position $Pos
        }
        "2" {
            # Offboard User
            $SamAccountName = Read-Host "Enter the username to offboard"
            Offboard-ADUser -SamAccountName $SamAccountName
        }
        "3" {
            Write-Host "Exiting... Goodbye!" -ForegroundColor Yellow
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
        }
    }
} while ($choice -ne "3")
