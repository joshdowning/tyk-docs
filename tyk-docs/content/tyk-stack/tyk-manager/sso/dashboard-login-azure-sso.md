---
date: 2018-01-24T17:02:11Z
title: Login into the Dashboard using Azure AD - Guide
menu:
   main:
      parent: "Single Sign On"
weight: 1
aliases:
  - /advanced-configuration/integrate/sso/dashboard-login-azure-sso/
---


This is an end-to-end worked example of how you can use [AzureAD](https://azure.microsoft.com/en-gb/services/active-directory/) and our [Tyk Identity Broker (TIB)](https://tyk.io/docs/concepts/tyk-components/identity-broker/
) to log in to your Dashboard.
This guide assumes the following:

* You already have authorised access to Tyk's Dashboard. If you haven't, [get the authorisation key by following this doc](/docs/basic-config-and-security/security/dashboard/create-users/#a-name-with-api-a-create-a-dashboard-user-with-the-api).

## Azures's side
1. Access your Azure Portal and navigate to the Azure Active Directory page.
2. Go to app registrations and create or access an application you want to use for Dashboard access.
  - if you are creating an application, give it a name and register it 
3. Add a redirect URL to your application as callback to TIB in your Azure application:
  - In your app, either via the Authentication menu or the redirect URL shortcut navigate to and add the redirect to TIB in the Web category i.e. `http://localhost:3000/auth/{PROFILE-NAME-IN-TIB}/openid-connect/callback`.
    (/docs/img/azureAD/redirect-URL.png)
4. Go to Overview and add a secret in Client Credentials. Don't forget to copy the secret value- not the secretID. 
    (/docs/img/azureAD/overview.png)

See their documentation for more detail: https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app

## Dashboard's side 
1. Log in to your dashboard and select Identity Management, located under System Management
2. Create a profile and select OpenID Connect as the provider type
3. Under Profile Configuration, paste the secret value, clientID, and Discover URL from the Azure site. 
  - Profile Configuation may look something like this:
  (/docs/img/azureAD/profile-configuration.png)
  - The Discover URL is created by Azure and can be located by selecting Endpoints on their site
  (/docs/img/azureAD/endpoints.png)
8. Test that it works:
   From the browser call `http://localhost:3000/auth/{PROFILE-NAME-IN-TIB}/openid-connect`
    - If it's working you'll be redirected to Azures's web page and will be asked to enter your Azure user name and password.
    - If you were successfully authenticated by Azure then you'll be redirected to the Tyk Dashboard and login into it without going through the login page. Job's done!

## The magic - The flow behind the scenes:
 1. The initial call to the endpoint on TIB was redirected to Azure
 2. Azure AD identified the user
 3. Azure redirected the call back to TIB endpoint (according to the callback you set up on the client earlier)
 4. TIB, via REST API call to the dashboard, created a nonce and a special session attached to it.
 5. TIB redirected the call to the dashboard to a special endpoint `/tap` ( it was defined on the profile under `ReturnURL`) with the nonce that was created.
 6. The Dashboard on the `/tap` endpoint finds the session that is attached to the `nonce`, login the user and redirect to the dashboard first page

{{< img src="/img/diagrams/generate-or-login-user-profile.png" alt="Generate Or Login User Profile flow" >}}

## Enhancements

Once it's working you can also add two more enhancements - SSO login page for the dashboard and automatic user group mapping from your AzureAD security groups or users groups to Tyk Dashboards RBAC groups

### SSO login into the dashboard via a login page
   You will need to:
	- set up a web server with a login page and a form for `user` and `password`
	- Update `tyk_analytics.conf` to redirect logins to that url
    Explicit details are in [steps 6-7]({{< ref "advanced-configuration/integrate/3rd-party-identity-providers/dashboard-login-ldap-tib#6-create-a-login-page" >}})

### User group mapping
You can specify User Groups within a TIB Profile. This can either be a static or dynamic setting.

```.json
{
  "DefaultUserGroupID": "{DEFAULT-TYK-USER-GROUP-ID}",
  "CustomUserGroupField": "{SCOPE}",
  "UserGroupMapping": {
    "{AZURE-GROUP-ID-ADMIN}": "{TYK-USER-GROUP-ID-ADMIN}",
    "{AZURE-GROUP-ID-READ-ONLY}": "{TYK-USER-GROUP-ID-READ-ONLY}",
  }
}
```
For a static setting, use DefaultUserGroupID
For a dynamic setting based on claims configured in Azure AD, use CustomUserGroupField with UserGroupMapping listing your User Groups and ID.

