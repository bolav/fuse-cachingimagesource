using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Reactive;
using Uno.UX;
using Fuse.Resources;
using Uno.Net.Http;
using Fuse.Drawing;
using Uno.IO;
using Fuse.Resources.Exif;
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
				if (String.IsNullOrEmpty(_url)){
				    _url = "http://i.imgur.com/fLoufZ6.png"; //_url is null or empty set img
				}
				else{
				    _url = value;
				}

			  string filename = Path.GetFileName(value);
				_filename = Path.Combine(Directory.GetUserDirectory(UserDirectory.Data), filename);
				if (File.Exists(_filename)) {
					// debug_log "Load file! " + _filename;
					var b = File.ReadAllBytes(_filename);
					TextureLoader.ByteArrayToTexture2DFilename(new Buffer(b), _filename, SetTexture);
				}
				else {
					// Now LoadBinary receives Action<>s
					Action<HttpResponseHeader, byte[]> httpc = HttpCallback;
					Action<string> lfailed = LoadFailed;
					HttpLoader.LoadBinary(value, httpc, lfailed);
				}

				//var his = _proxy as HttpImageSource;
				//his.Url = _url;
			}
		}

		void HttpCallback( HttpResponseHeader response, byte[] data ) {
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
				// debug_log "Writing " + data.Length + " to " + _filename;
				File.WriteAllBytes(_filename, data);

				TextureLoader.ByteArrayToTexture2DContentType(new Buffer(data), _contentType, SetTexture);
				_orientation = ExifData.FromByteArray(data).Orientation;
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

		ImageOrientation _orientation = ImageOrientation.Identity;
		public override ImageOrientation Orientation {
			get {
				return _orientation;
			}
		}

	}
