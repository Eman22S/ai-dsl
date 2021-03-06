module Lib
import Prelude.Doubles as db

export
stopwords : List String
stopwords = ["the", "a", "and", "is", "be", "will", "is"] 

export
nums : String
nums = "0123456789!@#$%^&*()_+=-:;"

export
removeStopWords : String -> List String
removeStopWords line = do
              let tmp = words line
              foldr (\x, acc => if elem x stopwords then acc else x::acc ) [] tmp

export
makeWordPairs : List String -> List (String, String)
makeWordPairs [] = []
makeWordPairs (x::y::z::h::xs) = (x,y)::(x,z)::(y,z)::(y,h)::(z,x)::(z,y)::(z,h)::(h,x)::(h,y)::(h,z)::makeWordPairs xs
makeWordPairs (x::y::z::xs) = (x,y)::(x,z)::(y,z)::(z,x)::(z,y)::makeWordPairs xs
makeWordPairs (x::y::xs) = (x,y)::makeWordPairs xs

export
createDictionary : List String ->  List (String, Nat)
createDictionary xss = func 0 tmp 
              where
                tmp = sort . nub $ xss
                func : Nat -> List String -> List (String, Nat)
                func _ [] = []
                func Z (x::xs) = (x, S Z) :: func (S (S Z)) xs
                func (S k) (x::xs) = (x, S k) :: func (S (S k) ) xs


export
insertAt : List Double -> Double -> Nat -> List Double
insertAt [] elem pos = []
insertAt (x::xs) elem  Z = elem::x::xs
insertAt (x::xs) elem (S Z) = x::elem::xs
insertAt (x::xs) elem (S k) = x::insertAt xs elem k 

export
oneHotEncoder : List Nat -> List Double -> List (List Double)
oneHotEncoder ws zs = foldr(\x, acc => (insertAt zs 1.0 x)::acc) [] ws

export
matrix_gen : Num j =>  List j -> List j -> List (List j )
matrix_gen ws zs = foldr (\x, acc => zs::acc) [] ws

b : Double
b = 0.3

export
softmax_activation : List Double -> List Double
softmax_activation xs = let softmax_denom = sum $ map exp $ xs 
in foldr (\x,acc => (exp x)/softmax_denom::acc) [] xs

export
nn_Layer : List Double -> List Double -> List Double
nn_Layer [] _ = []
nn_Layer _ [] = []
nn_Layer [] [] = []
nn_Layer (x::xs) (y::ys) = (x * y + b)::nn_Layer xs ys


export
grad_CrossEntropy : List Double -> List Double -> List Double
grad_CrossEntropy [] _ = []
grad_CrossEntropy _ [] = []
grad_CrossEntropy [] [] = []
grad_CrossEntropy (x::xs) (y::ys) = -(y/x) + (1-y)/(1-x)::grad_CrossEntropy xs ys

export
adam_Optimizer : List Double -> List Double -> Double -> Double -> Double -> Double -> Double -> Double -> List Double
adam_Optimizer [] _ _ _ _ _ _ _ =  []
adam_Optimizer _ [] _ _ _ _ _ _ =  []
adam_Optimizer (t::thetas) (gt::gts) alpha m_prev v_prev beta1 beta2 epsilon = do
              let m_current = (beta1 * m_prev + (1-beta1) * gt)/ (1-beta1)
              let v_current = (beta2 * v_prev + (1-beta2) *  (db.pow gt 2))/(1-(db.pow beta2 2))
              let mhat_current = m_current /(1-beta1)
              let vhat_current = v_current/(1-beta2)
              (t - alpha * mhat_current / ((sqrt  vhat_current) + epsilon)):: adam_Optimizer thetas gts alpha m_current v_current beta1 beta2 epsilon

export
wordpairs : List String -> List (String,String)
wordpairs wrds = makeWordPairs wrds

export
xss : List (String, String) -> List String
xss wordpairs = map (\(a,b) => a ) wordpairs

export
yss : List (String,String) -> List String
yss wordpairs = map (\(a,b) => b ) wordpairs


export
wordify : List String -> List String
wordify [] = []
wordify (fst::xss) =
            let bn = words fst
            in bn ++ wordify xss 


export
rawToDict : List String -> List (String,Nat)
rawToDict [] = []
rawToDict dataset = let some_var = wordify dataset
                    in createDictionary some_var

export
rawToCleaned : List String -> List String
rawToCleaned [] = []
rawToCleaned (x::xs) = let some_var = removeStopWords x
                       in some_var ++ rawToCleaned xs
export
fullNNLayer : List (List Double) -> List (List Double) -> List (List Double)
fullNNLayer [] [] = []
fullNNLayer (x::inputs) (y::weights) = (softmax_activation $ nn_Layer x y)::fullNNLayer inputs weights

export
loss_func : (List Double -> List Double -> List Double ) -> List (List Double) -> List (List Double) -> List (List Double)
loss_func f [] _ = []
loss_func f _ [] = []
loss_func f [] [] = []
loss_func f (p::preds) (t::targets) = f p t :: loss_func f preds targets

export
optimizer : ( List Double -> List Double -> Double -> Double -> Double -> Double -> Double -> Double -> List Double) -> List (List Double) -> List (List Double) -> Double -> Double -> Double -> Double -> Double -> Double -> List (List Double)
optimizer f [] _ _ _ _ _ _ _ = []
optimizer f _ [] _ _ _ _ _ _ = []
optimizer f [] [] _ _ _ _ _ _= []
optimizer f (ws::wss) (cs::costs) alpha  m v beta1 beta2 epsilon =  (f ws cs alpha m v beta1 beta2 epsilon) :: optimizer f wss costs alpha m  v beta1 beta2 epsilon

export
model : List (List Double) -> List (List Double) -> List (List Double) -> Double -> Double -> Double -> Double -> Int -> List (List Double )
model [] _ _ _ _ _ _ _ = []
model _ [] _ _ _ _ _ _ = []
model _ _ [] _ _ _ _ _ = []
model [] [] [] _ _ _ _ _= []
model weights inputs targets alpha beta1 beta2 epsilon iterations = case iterations == 0 of                         
                                              True => weights
                                              False => do
                                                  let predicted = fullNNLayer inputs weights
                                                  let full_cost = loss_func grad_CrossEntropy predicted targets 
                                                  let new_weights = optimizer adam_Optimizer weights full_cost alpha 0.0 0.0 beta1 beta2 epsilon 
                                                  model new_weights inputs targets alpha beta1 beta2 epsilon (iterations - 1)



