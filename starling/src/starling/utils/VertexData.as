// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
    /** The VertexData class manages a raw list of vertex information, allowing direct upload
     *  to Stage3D vertex buffers. <em>You only have to work with this class if you create display 
     *  objects with a custom render function. If you don't plan to do that, you can safely 
     *  ignore it.</em>
     * 
     *  <p>To render objects with Stage3D, you have to organize vertex data in so-called
     *  vertex buffers. Those buffers reside in graphics memory and can be accessed very 
     *  efficiently by the GPU. Before you can move data into vertex buffers, you have to 
     *  set it up in conventional memory - that is, in a Vector object. The vector contains
     *  all vertex information (the coordinates, color, and texture coordinates) - one
     *  vertex after the other.</p>
     *  
     *  <p>To simplify creating and working with such a bulky list, the VertexData class was 
     *  created. It contains methods to specify and modify vertex data. The raw Vector managed 
     *  by the class can then easily be uploaded to a vertex buffer.</p>
     * 
     *  <strong>Premultiplied Alpha</strong>
     *  
     *  <p>The color values of the "BitmapData" object contain premultiplied alpha values, which 
     *  means that the <code>rgb</code> values were multiplied with the <code>alpha</code> value 
     *  before saving them. Since textures are created from bitmap data, they contain the values in 
     *  the same style. On rendering, it makes a difference in which way the alpha value is saved; 
     *  for that reason, the VertexData class mimics this behavior. You can choose how the alpha 
     *  values should be handled via the <code>premultipliedAlpha</code> property.</p>
     * 
     *  <p><em>Note that vertex data with premultiplied alpha values will lose all <code>rgb</code>
     *  information of a vertex with a zero <code>alpha</code> value.</em></p> 
     */ 
    public class VertexData 
    {
        /** The total number of elements (Numbers) stored per vertex. */
        public static const ELEMENTS_PER_VERTEX:int = 9;
        
        /** The offset of position data (x, y) within a vertex. */
        public static const POSITION_OFFSET:int = 0;
        
        /** The offset of color data (r, g, b, a) within a vertex. */ 
        public static const COLOR_OFFSET:int = 3;
        
        /** The offset of texture coordinate (u, v) within a vertex. */
        public static const TEXCOORD_OFFSET:int = 7;
        
        private var mRawData:Vector.<Number>;
        private var mPremultipliedAlpha:Boolean;
        private var mNumVertices:int;
        
        /** Create a new VertexData object with a specified number of vertices. */
        public function VertexData(numVertices:int, premultipliedAlpha:Boolean=false)
        {            
            mRawData = new Vector.<Number>(numVertices * ELEMENTS_PER_VERTEX);
            mPremultipliedAlpha = premultipliedAlpha;
            mNumVertices = numVertices;
        }

        /** Creates a duplicate of the vertex data object. */
        public function clone():VertexData
        {
            var clone:VertexData = new VertexData(0, mPremultipliedAlpha);
            clone.mRawData = mRawData.concat();
            return clone;
        }
        
        /** Copies the vertex data of this instance to another vertex data object,
         *  starting at a certain index. */
        public function copyTo(targetData:VertexData, targetVertexID:int=0):void
        {
            // todo: check/convert pma
            
            var targetRawData:Vector.<Number> = targetData.mRawData;
            var dataLength:int = mNumVertices * ELEMENTS_PER_VERTEX;
            var targetStartIndex:int = targetVertexID * ELEMENTS_PER_VERTEX;
            
            for (var i:int=0; i<dataLength; ++i)
                targetRawData[targetStartIndex+i] = mRawData[i];
        }
        
        /** Appends the vertices from another VertexData object. */
        public function append(data:VertexData):void
        {
            for each (var element:Number in data.mRawData)
                mRawData.push(element);
        }
        
        // functions
        
        /** Updates the position values of a vertex. */
        public function setPosition(vertexID:int, x:Number, y:Number, z:Number=0.0):void
        {
            setValues(getOffset(vertexID) + POSITION_OFFSET, x, y, z);
        }
        
        /** Returns the position of a vertex. */
        public function getPosition(vertexID:int):Vector3D
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            return new Vector3D(mRawData[offset], mRawData[offset+1], mRawData[offset+2]);
        }
        
        /** Updates the color and alpha values of a vertex. */ 
        public function setColor(vertexID:int, color:uint, alpha:Number=1.0):void
        {
            var multiplier:Number = mPremultipliedAlpha ? alpha : 1.0;
            setValues(getOffset(vertexID) + COLOR_OFFSET, 
                      Color.getRed(color)   / 255.0 * multiplier,
                      Color.getGreen(color) / 255.0 * multiplier,
                      Color.getBlue(color)  / 255.0 * multiplier,
                      alpha);
        }
        
        /** Returns the RGB color of a vertex (no alpha). */
        public function getColor(vertexID:int):uint
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET;
            var divisor:Number = mPremultipliedAlpha ? mRawData[offset+3] : 1.0;
            
            if (divisor == 0) return 0;
            else
            {
                var red:Number   = mRawData[offset  ] / divisor;
                var green:Number = mRawData[offset+1] / divisor;
                var blue:Number  = mRawData[offset+2] / divisor;
                return Color.rgb(red * 255, green * 255, blue * 255);
            }
        }
        
        /** Updates the alpha value of a vertex (range 0-1). */
        public function setAlpha(vertexID:int, alpha:Number):void
        {
            if (mPremultipliedAlpha) setColor(vertexID, getColor(vertexID), alpha);
            else 
            {
                var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
                mRawData[offset] = alpha;
            }
        }
        
        /** Returns the alpha value of a vertex in the range 0-1. */
        public function getAlpha(vertexID:int):Number
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
            return mRawData[offset];
        }
        
        /** Updates the texture coordinates of a vertex (range 0-1). */
        public function setTexCoords(vertexID:int, u:Number, v:Number):void
        {
            setValues(getOffset(vertexID) + TEXCOORD_OFFSET, u, v);
        }
        
        /** Returns the texture coordinates of a vertex in the range 0-1. */
        public function getTexCoords(vertexID:int):Point
        {
            var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
            return new Point(mRawData[offset], mRawData[offset+1]);
        }
        
        // utility functions
        
        /** Translate the position of a vertex by a certain offset. */
        public function translateVertex(vertexID:int, 
                                        deltaX:Number, deltaY:Number, deltaZ:Number=0.0):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            mRawData[offset]   += deltaX;
            mRawData[offset+1] += deltaY;
            mRawData[offset+2] += deltaZ;
        }
        
        /** Transforms the position of a vertex by multiplication with a transformation matrix. */
        public function transformVertex(vertexID:int, matrix:Matrix3D=null):void
        {
            var position:Vector3D = getPosition(vertexID);
            
            if (matrix)
            {
                var transPosition:Vector3D = matrix.transformVector(position);
                setPosition(vertexID, transPosition.x, transPosition.y, transPosition.z);
            }
        }
        
        /** Sets all vertices of the object to the same color and alpha values. */
        public function setUniformColor(color:uint, alpha:Number=1.0):void
        {
            for (var i:int=0; i<mNumVertices; ++i)
                setColor(i, color, alpha);
        }
        
        /** Multiplies the alpha value of a vertex with a certain delta. */
        public function scaleAlpha(vertexID:int, alpha:Number):void
        {
            if (mPremultipliedAlpha) setAlpha(vertexID, getAlpha(vertexID) * alpha);
            else
            {
                var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
                mRawData[offset] *= alpha;
            }
        }
        
        private function setValues(offset:int, ...values):void
        {
            var numValues:int = values.length;
            for (var i:int=0; i<numValues; ++i)
                mRawData[offset+i] = values[i];
        }
        
        private function getOffset(vertexID:int):int
        {
            return vertexID * ELEMENTS_PER_VERTEX;
        }
        
        // properties
        
        /** Changes the way alpha and color values are stored. Updates all exisiting vertices. */
        public function set premultipliedAlpha(value:Boolean):void
        {
            if (value == mPremultipliedAlpha) return;            
            var dataLength:int = mNumVertices * ELEMENTS_PER_VERTEX;
            
            for (var i:int=COLOR_OFFSET; i<dataLength; i += ELEMENTS_PER_VERTEX)
            {
                var alpha:Number = mRawData[i+3];
                var divisor:Number = mPremultipliedAlpha ? alpha : 1.0;
                var multiplier:Number = value ? alpha : 1.0;
                
                if (divisor != 0)
                {
                    mRawData[i  ] = mRawData[i  ] / divisor * multiplier;
                    mRawData[i+1] = mRawData[i+1] / divisor * multiplier;
                    mRawData[i+2] = mRawData[i+2] / divisor * multiplier;
                }
            }
            
            mPremultipliedAlpha = value;
        }
        
        /** Trims rawData by removing obsolete elements. */
        public function trim():void
        {
            var elementsToRemove:int = mNumVertices * ELEMENTS_PER_VERTEX - mRawData.length;
            for (var i:int=0; i<elementsToRemove; ++i)
                mRawData.pop();
        }
        
        /** Indicates if the rgb values are stored premultiplied with the alpha value. */
        public function get premultipliedAlpha():Boolean { return mPremultipliedAlpha; }
        
        /** The total number of vertices. */
        public function get numVertices():int { return mNumVertices; }
        
        public function set numVertices(value:int):void
        {
            if (value > mNumVertices)
            {
                var elementsToAdd:int = (value - mNumVertices) * ELEMENTS_PER_VERTEX;
                for (var i:int = 0; i<elementsToAdd; ++i)
                    mRawData.push(0.0);
            }
            
            mNumVertices = value;
        }
        
        /** The raw vertex data; not a copy! */
        public function get rawData():Vector.<Number> { return mRawData; }
    }
}