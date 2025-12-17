# Supabase Storage Setup Guide

This guide explains how to set up Supabase Storage for car images in the Rental Management System.

## Prerequisites

- Active Supabase project
- Project URL and anon key configured in `lib/config/supabase_config.dart`
- Flutter project dependencies installed

## Storage Bucket Setup

### 1. Create the Storage Bucket

1. Open your [Supabase Dashboard](https://app.supabase.com)
2. Navigate to your project
3. Go to **Storage** in the left sidebar
4. Click **New Bucket**
5. Enter the following details:
   - **Name**: `car-images`
   - **Public**: ✓ Enable (for read access)
   - **File size limit**: 5MB (optional)
   - **Allowed MIME types**: `image/jpeg, image/png` (optional)
6. Click **Create Bucket**

### 2. Configure RLS Policies

Row Level Security (RLS) policies control who can access the bucket.

#### Allow Public Read Access

```sql
-- Policy for public SELECT (read) access
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'car-images' );
```

#### Allow Authenticated Users to Upload

```sql
-- Policy for authenticated INSERT (upload) access
CREATE POLICY "Authenticated users can upload car images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'car-images' );
```

#### Allow Authenticated Users to Update

```sql
-- Policy for authenticated UPDATE access
CREATE POLICY "Authenticated users can update car images"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'car-images' );
```

#### Allow Authenticated Users to Delete

```sql
-- Policy for authenticated DELETE access
CREATE POLICY "Authenticated users can delete car images"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'car-images' );
```

### 3. Apply Policies via Supabase Dashboard

1. In **Storage** → Click on `car-images` bucket
2. Go to **Policies** tab
3. Click **New Policy**
4. For each policy above:
   - Choose the appropriate operation (SELECT, INSERT, UPDATE, DELETE)
   - Set the target role (public for SELECT, authenticated for others)
   - Add the policy definition
   - Click **Review** and **Save**

## File Structure

The storage service organizes files as follows:

```
car-images/
├── {carId1}/
│   ├── {timestamp}_{uuid}.jpg
│   └── {timestamp}_{uuid}.jpg
├── {carId2}/
│   └── {timestamp}_{uuid}.jpg
└── ...
```

Each car has its own folder, making it easy to:
- Manage multiple images per car (future enhancement)
- Delete all images when a car is removed
- Organize and maintain the storage

## Image Specifications

### Supported Formats
- JPEG (.jpg, .jpeg)
- PNG (.png)

### Size Limits
- **Maximum upload size**: 5MB (before compression)
- **Target compressed size**: < 1MB
- **Dimensions**: Automatically resized to max 800x600 (maintains aspect ratio)

### Compression
Images are automatically compressed before upload:
- Resized to fit within 800x600 pixels
- Converted to JPEG format
- Quality: 85%
- Reduces file size significantly for faster loading

## Usage in Application

### Upload Image (Admin Panel)

1. Navigate to **Admin Dashboard** → **Manage Cars**
2. Click **Add Car** or edit an existing car
3. Click the image placeholder
4. Choose **Gallery** or **Camera**
5. Select/capture image
6. Image is automatically compressed and uploaded
7. Progress indicator shows upload status

### Update Car Image

1. Click **Edit** on any car card
2. Click the image or the edit icon
3. Select new image from gallery or camera
4. Old image is automatically deleted
5. New image is uploaded and compressed

### Delete Car

When a car is deleted:
1. All associated images in `car-images/{carId}/` are removed
2. Database record is deleted
3. Storage is cleaned up automatically

## Troubleshooting

### Upload Fails

**Error**: "File size exceeds 5MB limit"
- **Solution**: The original image is too large. Try selecting a smaller image or the app will compress it automatically.

**Error**: "Invalid file format"
- **Solution**: Only JPEG and PNG formats are supported. Convert your image to one of these formats.

**Error**: "Upload failed after 3 attempts"
- **Solution**: Check your internet connection and Supabase service status.

### Bucket Not Found

**Error**: "Bucket check failed" or "404 Not Found"
- **Solution**: 
  1. Verify the bucket name is exactly `car-images`
  2. Ensure the bucket exists in your Supabase project
  3. Check that the bucket is set to public

### Permission Denied

**Error**: "new row violates row-level security policy"
- **Solution**:
  1. Ensure you're logged in as an authenticated user
  2. Verify RLS policies are correctly configured
  3. Check that policies allow your user's role

### Images Not Displaying

**Problem**: Images don't load in the app
- **Solution**:
  1. Check that the bucket is set to **Public**
  2. Verify the image URL is correct
  3. Check your internet connection
  4. Ensure the image file exists in storage

## Security Best Practices

1. **Never store sensitive data in public buckets**
   - The `car-images` bucket is public for reading
   - Only car images should be stored here

2. **Use authentication for uploads**
   - Only authenticated admin users can upload/modify images
   - Configure RLS policies to enforce this

3. **Validate uploads**
   - The app validates file format and size
   - Server-side validation provides additional security

4. **Regular cleanup**
   - Delete orphaned images periodically
   - Monitor storage usage in Supabase Dashboard

## Monitoring

### Check Storage Usage

1. Go to Supabase Dashboard → **Storage**
2. View total storage used
3. Monitor individual bucket sizes
4. Set up alerts for quota limits

### View Uploaded Files

1. Go to **Storage** → `car-images` bucket
2. Browse folders by car ID
3. Preview images
4. Download or delete files manually if needed

## Cost Considerations

Supabase Storage pricing (as of 2024):
- **Free tier**: 1GB storage
- **Pro tier**: 100GB included, then $0.021/GB/month
- **Bandwidth**: Free tier includes 2GB, Pro includes 250GB

**Optimization tips**:
- Image compression reduces storage costs
- Delete old/unused images
- Monitor usage regularly

## Additional Resources

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [RLS Policies Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Flutter Supabase Integration](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Supabase Storage logs
3. Check application logs for detailed error messages
4. Consult Supabase community forums
