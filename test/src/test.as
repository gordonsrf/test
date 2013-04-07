package
{
	import com.renaun.flascc.CModule;
	import com.renaun.flascc_interface.flascc_initMap;
	import com.renaun.flascc_interface.flascc_initSysterm;
	import com.renaun.flascc_interface.flascc_switchDebugMode;
	
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	public class test extends Sprite
	{
		protected var context3D:Context3D;
		protected var program:Program3D;
		protected var vertexbuffer:VertexBuffer3D;
		protected var indexbuffer:IndexBuffer3D;
		public function test()
		{
			CModule.startAsync(this);
			var bytes:ByteArray = new ByteArray();
			bytes.writeUnsignedInt(1);
			bytes.writeUnsignedInt(2);
			bytes.writeUnsignedInt(3);
			bytes.position = 0;
			
			flascc_initSysterm();
			flascc_switchDebugMode(1);
			
			var index:int = CModule.malloc(bytes.length);
			flascc_initMap(1,2,bytes.length,index);
			/*var lib:* = new CLibInit().init();
			lib.initSys();*/
			
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE,onCreatureContext3d);
			stage.stage3Ds[0].requestContext3D();
			stage.stage3Ds[0].addEventListener(ErrorEvent.ERROR, onStage3DError);
		}
		
		protected function onStage3DError(event:ErrorEvent = null):void
		{
			trace("error");
		}
		
		private function onCreatureContext3d(event:Event):void
		{
			context3D = stage.stage3Ds[0].context3D;
			if(context3D == null)
			{
				onStage3DError();
				return;
			}
			var isHW:Boolean = context3D.driverInfo.toLowerCase().indexOf("software") == -1;
			if(isHW)
			{
				context3D.configureBackBuffer(800, 600, 1, true);
				
				var vertices:Vector.<Number> = Vector.<Number>([
					-0.3,-0.3,0, 1, 0, 0, // x, y, z, r, g, b
					-0.3, 0.3, 0, 0, 1, 0,
					0.3, 0.3, 0, 0, 0, 1]);
				
				// Create VertexBuffer3D. 3 vertices, of 6 Numbers each
				vertexbuffer = context3D.createVertexBuffer(3, 6);
				// Upload VertexBuffer3D to GPU. Offset 0, 3 vertices
				vertexbuffer.uploadFromVector(vertices, 0, 3);				
				
				var indices:Vector.<uint> = Vector.<uint>([0, 1, 2]);
				
				// Create IndexBuffer3D. Total of 3 indices. 1 triangle of 3 vertices
				indexbuffer = context3D.createIndexBuffer(3);			
				// Upload IndexBuffer3D to GPU. Offset 0, count 3
				indexbuffer.uploadFromVector (indices, 0, 3);			
				
				var vertexShaderAssembler : AGALMiniAssembler = new AGALMiniAssembler();
				vertexShaderAssembler.assemble( Context3DProgramType.VERTEX,
					"m44 op, va0, vc0\n" + // pos to clipspace
					"mov v0, va1" // copy color
				);			
				
				var fragmentShaderAssembler : AGALMiniAssembler= new AGALMiniAssembler();
				fragmentShaderAssembler.assemble( Context3DProgramType.FRAGMENT,
					
					"mov oc, v0"
				);
				
				program = context3D.createProgram();
				program.upload( vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
				addEventListener(Event.ENTER_FRAME, onRender);
			}
			else
			{
				onStage3DError();
			}
		}
		
		protected function onRender(e:Event):void
		{
			if ( !context3D ) 
				return;
			
			context3D.clear ( 1, 1, 1, 1 );
			
			// vertex position to attribute register 0
			context3D.setVertexBufferAt (0, vertexbuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			// color to attribute register 1
			context3D.setVertexBufferAt(1, vertexbuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
			// assign shader program
			context3D.setProgram(program);
			
			var m:Matrix3D = new Matrix3D();
			m.appendRotation(getTimer()/40, Vector3D.Z_AXIS);
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
			
			context3D.drawTriangles(indexbuffer);
			
			context3D.present();			
		}
	}
}