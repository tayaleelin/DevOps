import pulumi
from pulumi_azure_native import storage
from pulumi_azure_native import resources

# Create an Azure Resource Group
resource_group = resources.ResourceGroup("resource_group")

# Create an Azure resource (Storage Account)
account = storage.StorageAccount('sa',
                                 resource_group_name=resource_group.name,
                                 sku=storage.SkuArgs(
                                     name=storage.SkuName.STANDARD_LRS,
                                 ),
                                 kind=storage.Kind.STORAGE_V2)

# Export the primary key of the Storage Account
primary_key = storage.list_storage_account_keys_output(
    resource_group_name=resource_group.name,
    account_name=account.name
).keys[0].value
pulumi.export("primary_storage_key", primary_key)

static_website = storage.StorageAccountStaticWebsite("staticWebsite",
                                                     account_name=account.name,
                                                     resource_group_name=resource_group.name,
                                                     index_document="index.html")

index_html = storage.Blob("index.html",
                          resource_group_name=resource_group.name,
                          account_name=account.name,
                          container_name=static_website.container_name,
                          source=pulumi.FileAsset("index.html"),
                          content_type="text/html")

pulumi.export("staticEndpoint", account.primary_endpoints.web)


def PublishWebsite():
    print('I am publishing something')


PublishWebsite()
