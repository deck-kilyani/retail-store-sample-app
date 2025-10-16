# DNS Setup Instructions for tastydrive.store

## Current Status
- Domain: `tastydrive.store`
- Load Balancer: `k8s-ingressn-ingressn-20b823d43b-288c381c05803223.elb.us-west-2.amazonaws.com`
- Certificate Status: Pending (waiting for DNS resolution)

## Required DNS Configuration

You need to create a CNAME record in your DNS provider (where tastydrive.store is registered) with the following details:

### CNAME Record
```
Type: CNAME
Name: @ (or leave blank for root domain)
Value: k8s-ingressn-ingressn-20b823d43b-288c381c05803223.elb.us-west-2.amazonaws.com
TTL: 300 (5 minutes) or your provider's default
```

### Alternative: A Record (if CNAME for root domain is not supported)
If your DNS provider doesn't support CNAME records for the root domain, you can create an A record:

```
Type: A
Name: @ (or leave blank for root domain)
Value: 44.225.209.112
TTL: 300 (5 minutes)
```

**Note:** AWS Load Balancer IP addresses can change, so CNAME is preferred if supported.

## Steps to Configure DNS

1. **Log into your DNS provider** (where tastydrive.store is registered)
2. **Navigate to DNS management** (usually called "DNS", "Name Servers", or "DNS Records")
3. **Add the CNAME record** as specified above
4. **Save the changes**
5. **Wait for DNS propagation** (usually 5-15 minutes, can take up to 48 hours)

## Verification Commands

After setting up the DNS record, verify it's working:

```bash
# Check if the domain resolves
nslookup tastydrive.store

# Check if it points to the correct load balancer
dig tastydrive.store CNAME

# Test HTTP access (should work after DNS propagates)
curl -I http://tastydrive.store

# Check certificate status (after DNS is working)
kubectl get certificates -n retail-store
```

## Common DNS Providers

### Cloudflare
1. Go to cloudflare.com and log in
2. Select your domain
3. Go to "DNS" tab
4. Click "Add record"
5. Select "CNAME", enter "@" for name, and the load balancer hostname for target

### Route 53 (AWS)
1. Go to Route 53 console
2. Select your hosted zone
3. Click "Create record"
4. Leave name blank, select "CNAME", enter the load balancer hostname

### GoDaddy
1. Go to GoDaddy DNS management
2. Click "Add" under DNS records
3. Select "CNAME", enter "@" for host, and the load balancer hostname for points to

### Namecheap
1. Go to Domain List and click "Manage" next to your domain
2. Go to "Advanced DNS" tab
3. Click "Add New Record"
4. Select "CNAME Record", enter "@" for host, and the load balancer hostname for value

## Troubleshooting

If the certificate is still not working after DNS propagation:

1. **Check DNS resolution:**
```bash
nslookup tastydrive.store
```

2. **Check certificate status:**
```bash
kubectl describe certificate tastydrive-store-tls -n retail-store
```

3. **Check challenge status:**
```bash
kubectl get challenges -n retail-store
kubectl describe challenge [challenge-name] -n retail-store
```

4. **Force certificate renewal:**
```bash
kubectl delete certificate tastydrive-store-tls -n retail-store
# The certificate will be automatically recreated
```

## Next Steps

Once DNS is configured and propagated:
1. The Let's Encrypt challenge will automatically complete
2. The SSL certificate will be issued
3. The application will be accessible via https://tastydrive.store
4. HTTP requests will automatically redirect to HTTPS