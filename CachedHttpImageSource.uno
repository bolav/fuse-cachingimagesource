using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Reactive;
using Uno.UX;
using Fuse.Resources;
using Fuse.Designer;
using Fuse.Drawing;
using Uno.IO;

using Experimental.TextureLoader;
using Experimental.Http;


	public sealed class CachedHttpImageSource : ImageSource
	{
		texture2D texture = null;

		String _filename;
		String _url;
		public String Url
		{
			get {
				return _url;
			}
			set { 
				// debug_log "CachedHttpImageSource setting url " + value;
				_url = value;
				_filename = Path.Combine(Directory.GetUserDirectory(UserDirectory.Data), Url.GetHashCode() + ".jpg");
				if (File.Exists(_filename)) {
					// debug_log "Load file! " + _filename;
					var b = File.ReadAllBytes(_filename);
					TextureLoader.ByteArrayToTexture2DFilename(new Buffer(b), _filename, SetTexture);
				}
				else {
					HttpLoader.LoadBinary(Url, HttpCallback, LoadFailed);
				}

				//var his = _proxy as HttpImageSource;
				//his.Url = _url;
			}
		}

		void HttpCallback( HttpResponseHeader response, Buffer data ) {
			debug_log "HttpCallback";
			var _contentType = "";
			if (response.StatusCode != 200)
			{
				return;
			}
			
			string ct;
			if (!response.Headers.TryGetValue("content-type",out ct))
				_contentType = "x-missing";
			else
				_contentType = ct;
					
			try
			{
				var files_buf = new byte[data.SizeInBytes];
				for (var i=0; i<data.SizeInBytes; i++) {
					files_buf[i] = data[i];
				}
				debug_log "Writing " + data.SizeInBytes + " to " + _filename;
				File.WriteAllBytes(_filename, files_buf);

				TextureLoader.ByteArrayToTexture2DContentType(data, _contentType, SetTexture);
				OnChanged();
			}
			catch( Exception e )
			{
				return;
			}
		}

		void LoadFailed( string reason ) {
			debug_log "Loading failed " + reason;
		}
		
		public CachedHttpImageSource() : base()
		{
		}

		public CachedHttpImageSource(String url) : base()
		{
			debug_log "new CachedHttpImageSource(url)";
			Url = url;
		}

		protected override void OnPinChanged() {
			base.OnPinChanged();
		}
		public override float2 Size {
			get {
				return float2(PixelSize.X / SizeDensity, PixelSize.Y / SizeDensity);
			}
		}

		public override int2 PixelSize {
			get {
				if (texture != null) {
					return texture.Size.XY;
				} else return int2(1, 1);
			}
		}

		public override float SizeDensity {
			get {
				return 1.0f;
			}
		}

		void SetTexture(texture2D texture) {
			this.texture = texture;
			imageSourceState = ImageSourceState.Ready;
		}

		ImageSourceState imageSourceState = ImageSourceState.Pending;
		public override ImageSourceState State {
			get {
				return imageSourceState;
			}
		}

		public override texture2D GetTexture() {
			// debug_log "Show file " + _filename;
			return texture;
		}

	}
